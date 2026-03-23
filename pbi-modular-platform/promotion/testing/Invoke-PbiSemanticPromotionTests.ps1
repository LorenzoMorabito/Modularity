[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [string]$ProjectPath,
    [string]$OutputRoot,
    [switch]$KeepArtifacts
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$promotionRoot = Split-Path -Parent $scriptRoot
$platformRoot = Split-Path -Parent $promotionRoot
$invokeModularityScript = Join-Path $platformRoot "Invoke-PbiModularity.ps1"
$fixtureRoot = Join-Path $scriptRoot "fixtures"
$pwshPath = (Get-Command pwsh -ErrorAction Stop).Source

$runtimeModulePath = Join-Path $platformRoot "installer/Modules/Core/Pbi.Runtime.psm1"
Import-Module $runtimeModulePath -Force -DisableNameChecking
$resolvedWorkspaceRoot = Get-PbiInstallerWorkspaceRoot -WorkspaceRoot $WorkspaceRoot -ScriptRoot $platformRoot

$modulePaths = @(
    $runtimeModulePath,
    (Join-Path $platformRoot "installer/Modules/Core/Pbi.Schema.psm1"),
    (Join-Path $platformRoot "installer/Modules/Core/Pbi.Project.psm1"),
    (Join-Path $platformRoot "testing/Modules/Common/Pbi.TestResults.psm1"),
    (Join-Path $promotionRoot "Modules/Core/Pbi.SemanticPromotion.Shared.psm1"),
    (Join-Path $promotionRoot "Modules/Core/Pbi.SemanticPromotion.Tmdl.psm1"),
    (Join-Path $promotionRoot "Modules/Core/Pbi.SemanticPromotion.psm1")
)

foreach ($modulePath in $modulePaths) {
    Import-Module $modulePath -Force -DisableNameChecking
}

$script:PromotionModule = Get-Module Pbi.SemanticPromotion

function Resolve-PbiPromotionTestProjectPath {
    param(
        [string]$WorkspaceRoot,
        [string]$ProjectPath
    )

    if ($ProjectPath) {
        return (Resolve-Path $ProjectPath).Path
    }

    $workspaceParent = Split-Path $WorkspaceRoot -Parent
    $defaultProjectPath = Join-Path $workspaceParent "pbi-sviluppi\powerbi-projects\test\test_001\sales_test_001.pbip"
    if (Test-Path $defaultProjectPath) {
        return (Resolve-Path $defaultProjectPath).Path
    }

    return $null
}

function Invoke-PbiPromotionInternal {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
        [object[]]$ArgumentList = @()
    )

    return (& $script:PromotionModule $ScriptBlock @ArgumentList)
}

function Normalize-PbiText {
    param([AllowNull()][string]$Text)

    if ($null -eq $Text) {
        return ""
    }

    return (($Text -replace "`r`n", "`n") -replace "`r", "`n").TrimEnd()
}

function Get-PbiComparableText {
    param([AllowNull()][string]$Text)

    $normalized = Normalize-PbiText -Text $Text
    $normalized = [regex]::Replace($normalized, "\x1b\[[0-9;]*m", "")
    $normalized = [regex]::Replace($normalized, "\s+", " ")
    return $normalized.Trim()
}

function Get-PbiNormalizedFileContent {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Normalize-PbiText -Text (Get-Content -Path $Path -Raw))
}

function Assert-PbiCondition {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-PbiEqual {
    param(
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Actual -ne $Expected) {
        throw ("{0} Expected='{1}' Actual='{2}'." -f $Message, $Expected, $Actual)
    }
}

function Assert-PbiContains {
    param(
        [Parameter(Mandatory = $true)][string]$ActualText,
        [Parameter(Mandatory = $true)][string]$ExpectedFragment,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $comparableActual = Get-PbiComparableText -Text $ActualText
    $comparableExpected = Get-PbiComparableText -Text $ExpectedFragment
    if ($comparableActual -notlike ("*" + $comparableExpected + "*")) {
        throw ("{0} Missing fragment '{1}'." -f $Message, $ExpectedFragment)
    }
}

function ConvertTo-PbiNormalizedJson {
    param([Parameter(Mandatory = $true)]$InputObject)

    return (ConvertTo-PbiJsonText -InputObject $InputObject -Compress)
}

function Ensure-PbiEmptyDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
    }

    Ensure-PbiDirectory -Path $Path
}

function Copy-PbiDirectoryContents {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$DestinationRoot,
        [string[]]$ExcludeNames = @()
    )

    Ensure-PbiDirectory -Path $DestinationRoot
    foreach ($item in @(Get-ChildItem -Path $SourceRoot -Force)) {
        if ($ExcludeNames -contains $item.Name) {
            continue
        }

        Copy-Item -Path $item.FullName -Destination (Join-Path $DestinationRoot $item.Name) -Recurse -Force
    }
}

function New-PbiPromotionProjectCopy {
    param(
        [Parameter(Mandatory = $true)][string]$SourceProjectPath,
        [Parameter(Mandatory = $true)][string]$DestinationRoot
    )

    $sourceProject = Resolve-PbiConsumerProject -ProjectPath $SourceProjectPath
    Ensure-PbiEmptyDirectory -Path $DestinationRoot
    Copy-PbiDirectoryContents -SourceRoot $sourceProject.ProjectRoot -DestinationRoot $DestinationRoot
    return (Resolve-PbiConsumerProject -ProjectPath (Join-Path $DestinationRoot ([System.IO.Path]::GetFileName($sourceProject.PbipPath))))
}

function Copy-PbiFixtureTablesToProject {
    param(
        [Parameter(Mandatory = $true)][string]$FixtureDirectory,
        [Parameter(Mandatory = $true)]$Project
    )

    $tablesRoot = Join-Path $Project.SemanticModelPath "definition/tables"
    foreach ($fixtureFile in @(Get-ChildItem -Path $FixtureDirectory -File -Filter "*.tmdl" | Sort-Object Name)) {
        Copy-Item -Path $fixtureFile.FullName -Destination (Join-Path $tablesRoot $fixtureFile.Name) -Force
    }
}

function Invoke-PbiModularityCommand {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][hashtable]$Parameters,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [switch]$ExpectFailure
    )

    $arguments = @("-NoProfile", "-File", $ScriptPath, "-Command", $CommandName)
    foreach ($key in $Parameters.Keys) {
        $value = $Parameters[$key]
        if ($null -eq $value) {
            continue
        }

        if ($value -is [bool]) {
            if ($value) {
                $arguments += ("-" + $key)
            }
            continue
        }

        $arguments += ("-" + $key)
        $arguments += ([string]$value)
    }

    $outputLines = & $pwshPath @arguments 2>&1 | ForEach-Object { $_.ToString() }
    $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    $outputText = (@($outputLines) + @("", "[exit-code] $exitCode")) -join [Environment]::NewLine
    Ensure-PbiDirectory -Path (Split-Path -Parent $LogPath)
    Write-PbiUtf8File -Path $LogPath -Content $outputText

    if ($ExpectFailure) {
        if ($exitCode -eq 0) {
            throw ("Command '{0}' was expected to fail but succeeded." -f $CommandName)
        }
    }
    elseif ($exitCode -ne 0) {
        throw ("Command '{0}' failed with exit code {1}. See {2}." -f $CommandName, $exitCode, $LogPath)
    }

    return [PSCustomObject]@{
        ExitCode    = $exitCode
        OutputText  = $outputText
        OutputLines = @($outputLines)
        LogPath     = $LogPath
    }
}

function Get-PbiFixtureExpectedManifest {
    param([Parameter(Mandatory = $true)][string]$ScenarioName)

    return (Read-PbiJsonFile -Path (Join-Path $fixtureRoot ("golden\" + $ScenarioName + "\expected\manifest.json")))
}

function Get-PbiFixtureInputDirectory {
    param([Parameter(Mandatory = $true)][string]$ScenarioName)

    return (Join-Path $fixtureRoot ("golden\" + $ScenarioName + "\input"))
}

function Get-PbiFixtureExpectedDirectory {
    param([Parameter(Mandatory = $true)][string]$ScenarioName)

    return (Join-Path $fixtureRoot ("golden\" + $ScenarioName + "\expected"))
}

function Get-PbiFailureFixtureInputDirectory {
    param([Parameter(Mandatory = $true)][string]$ScenarioName)

    return (Join-Path $fixtureRoot ("failure\" + $ScenarioName + "\input"))
}

function Get-PbiTargetFixtureInventory {
    param([switch]$IncludeAmbiguousSalesMeasure)

    $targetPaths = @(
        (Join-Path $fixtureRoot "targets\Corporation.tmdl"),
        (Join-Path $fixtureRoot "targets\Sales.tmdl")
    )

    if ($IncludeAmbiguousSalesMeasure) {
        $targetPaths += (Join-Path $fixtureRoot "targets\Sales Duplicate.tmdl")
    }

    return (Get-PbiTmdlInventoryMap -TablePaths $targetPaths)
}

function Invoke-PbiPromotionTestCase {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [Parameter(Mandatory = $true)][string]$ArtifactRoot
    )

    $caseRoot = Join-Path $ArtifactRoot $Name
    Ensure-PbiEmptyDirectory -Path $caseRoot

    try {
        & $Action $caseRoot
        return (New-PbiQualityResult -Scope "PromotionTest" -Target $Name -RuleId "promotion.test.pass" -Severity "Info" -Message "PASS" -Path $caseRoot)
    }
    catch {
        $errorPath = Join-Path $caseRoot "error.txt"
        $errorText = @(
            $_.Exception.Message,
            "",
            $_.ScriptStackTrace
        ) -join [Environment]::NewLine
        Write-PbiUtf8File -Path $errorPath -Content $errorText
        return (New-PbiQualityResult -Scope "PromotionTest" -Target $Name -RuleId "promotion.test.fail" -Severity "Error" -Message $_.Exception.Message -Path $errorPath)
    }
}

function Show-PbiPromotionTestResults {
    param([Parameter(Mandatory = $true)][object[]]$Results)

    $counts = Get-PbiQualityResultCounts -Results $Results
    Write-Host ("[INFO] Promotion test summary: Errors={0} Warnings={1} Infos={2} Total={3}" -f $counts.Errors, $counts.Warnings, $counts.Infos, $counts.Total)

    if (@($Results).Count -gt 0) {
        $Results |
            Sort-Object Severity, Target |
            Select-Object Severity, Target, RuleId, Message, Path |
            Format-Table -AutoSize
    }
}

function Write-PbiPromotionTestSummaryFiles {
    param(
        [Parameter(Mandatory = $true)][string]$OutputRoot,
        [Parameter(Mandatory = $true)][object[]]$Results
    )

    $summaryPath = Join-Path $OutputRoot "summary.json"
    $markdownPath = Join-Path $OutputRoot "summary.md"

    Write-PbiJsonFile -Path $summaryPath -InputObject ([PSCustomObject]@{
        generatedAt = Get-PbiUtcTimestamp
        counts      = (Get-PbiQualityResultCounts -Results $Results)
        results     = @($Results)
    })

    $lines = @(
        "# Semantic Promotion Tests",
        "",
        ('Generated at: `{0}`' -f (Get-PbiUtcTimestamp)),
        "",
        "## Results",
        ""
    )

    foreach ($result in @($Results | Sort-Object Severity, Target)) {
        $lines += ('- `{0}` | `{1}` | `{2}` | `{3}`' -f $result.Severity, $result.Target, $result.RuleId, $result.Message)
    }

    Write-PbiUtf8File -Path $markdownPath -Content ($lines -join [Environment]::NewLine)
}

function Invoke-PbiPromotionUnitTests {
    param([Parameter(Mandatory = $true)][string]$ArtifactRoot)

    $results = @()

    $results += Invoke-PbiPromotionTestCase -Name "unit.tmdl-parse-simple-input" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $definitions = @(Get-PbiTmdlObjectDefinitions -Path (Join-Path (Get-PbiFixtureInputDirectory -ScenarioName "simple") "_MOD Promo Test Inputs.tmdl"))
        Assert-PbiEqual -Actual $definitions.Count -Expected 4 -Message "Expected four TMDL definitions in the simple input fixture."
        Assert-PbiEqual -Actual $definitions[0].Type -Expected "measure" -Message "First definition should be a measure."
        Assert-PbiEqual -Actual $definitions[1].Type -Expected "measure" -Message "Second definition should be a measure."
        Assert-PbiEqual -Actual $definitions[2].Type -Expected "column" -Message "Third definition should be a column."
        Assert-PbiEqual -Actual $definitions[3].Type -Expected "partition" -Message "Fourth definition should be a partition."
    }

    $results += Invoke-PbiPromotionTestCase -Name "unit.external-reference-classification" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $inputPaths = @(
            (Join-Path (Get-PbiFixtureInputDirectory -ScenarioName "simple") "_MOD Promo Test Inputs.tmdl"),
            (Join-Path (Get-PbiFixtureInputDirectory -ScenarioName "simple") "MOD Promo Test.tmdl")
        )
        $moduleInventory = Get-PbiTmdlInventoryMap -TablePaths $inputPaths
        $targetInventory = Get-PbiTargetFixtureInventory
        $definitions = @()
        foreach ($path in $inputPaths) {
            $definitions += @(Get-PbiTmdlObjectDefinitions -Path $path)
        }

        $externalReferences = @(Get-PbiTmdlExternalReferences -Definitions $definitions -ModuleInventory $moduleInventory -TargetInventory $targetInventory)
        Assert-PbiEqual -Actual $externalReferences.Count -Expected 2 -Message "Expected two external references in the simple fixture."
        Assert-PbiCondition -Condition (@($externalReferences | Where-Object { $_.referenceType -eq "measure" -and $_.referenceText -eq "[Sales LE]" }).Count -eq 1) -Message "Expected one supported external measure reference."
        Assert-PbiCondition -Condition (@($externalReferences | Where-Object { $_.referenceType -eq "column" -and $_.referenceText -eq "Corporation[Corporation]" }).Count -eq 1) -Message "Expected one supported external column reference."
    }

    $results += Invoke-PbiPromotionTestCase -Name "unit.external-reference-ambiguous-measure" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $inputPaths = @(
            (Join-Path (Get-PbiFixtureInputDirectory -ScenarioName "simple") "_MOD Promo Test Inputs.tmdl"),
            (Join-Path (Get-PbiFixtureInputDirectory -ScenarioName "simple") "MOD Promo Test.tmdl")
        )
        $moduleInventory = Get-PbiTmdlInventoryMap -TablePaths $inputPaths
        $targetInventory = Get-PbiTargetFixtureInventory -IncludeAmbiguousSalesMeasure
        $definitions = @()
        foreach ($path in $inputPaths) {
            $definitions += @(Get-PbiTmdlObjectDefinitions -Path $path)
        }

        $externalReferences = @(Get-PbiTmdlExternalReferences -Definitions $definitions -ModuleInventory $moduleInventory -TargetInventory $targetInventory)
        $ambiguousMeasureRef = @($externalReferences | Where-Object { $_.referenceText -eq "[Sales LE]" } | Select-Object -First 1)
        Assert-PbiCondition -Condition ($null -ne $ambiguousMeasureRef) -Message "Expected the ambiguous measure reference to be detected."
        Assert-PbiEqual -Actual $ambiguousMeasureRef.supportStatus -Expected "manual-review" -Message "Expected the ambiguous measure reference to require manual review."
        Assert-PbiEqual -Actual $ambiguousMeasureRef.supportReason -Expected "ambiguous-unqualified-measure-reference" -Message "Expected the ambiguous measure reference reason code."

        $strictErrors = @(Invoke-PbiPromotionInternal -ScriptBlock {
            param([object[]]$References)
            Test-PbiSemanticPromotionStrictReferences -ExternalReferences $References
        } -ArgumentList @(,$externalReferences))
        Assert-PbiCondition -Condition (@($strictErrors | Where-Object { $_ -like "*review manuale*" }).Count -eq 1) -Message "Expected strict mode to block ambiguous measure references."
    }

    $results += Invoke-PbiPromotionTestCase -Name "unit.binding-candidate-generation" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $definitions = @(
            Get-PbiTmdlObjectDefinitions -Path (Join-Path (Get-PbiFixtureInputDirectory -ScenarioName "simple") "_MOD Promo Test Inputs.tmdl")
        )
        $bindingCandidates = @(Get-PbiSimpleBindingCandidates -Definitions $definitions -TargetInventory (Get-PbiTargetFixtureInventory))
        Assert-PbiEqual -Actual $bindingCandidates.Count -Expected 2 -Message "Expected two binding candidates in the simple fixture."
        Assert-PbiCondition -Condition (@($bindingCandidates | Where-Object { $_.kind -eq "measure" -and $_.bindingKey -eq "MOD_BIND_SALES_LE" }).Count -eq 1) -Message "Expected one measure binding candidate."
        Assert-PbiCondition -Condition (@($bindingCandidates | Where-Object { $_.kind -eq "column" -and $_.bindingKey -eq "MOD_BIND_CORPORATION_CORPORATION[Value]" }).Count -eq 1) -Message "Expected one column binding candidate."
    }

    $results += Invoke-PbiPromotionTestCase -Name "unit.binding-candidate-generation-ambiguous-measure" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $definitions = @(
            Get-PbiTmdlObjectDefinitions -Path (Join-Path (Get-PbiFixtureInputDirectory -ScenarioName "simple") "_MOD Promo Test Inputs.tmdl")
        )
        $bindingCandidates = @(Get-PbiSimpleBindingCandidates -Definitions $definitions -TargetInventory (Get-PbiTargetFixtureInventory -IncludeAmbiguousSalesMeasure))
        Assert-PbiEqual -Actual $bindingCandidates.Count -Expected 1 -Message "Expected only the column binding candidate when the measure name is ambiguous."
        Assert-PbiCondition -Condition (@($bindingCandidates | Where-Object { $_.kind -eq "measure" }).Count -eq 0) -Message "Did not expect a measure binding candidate for an ambiguous measure name."
    }

    $results += Invoke-PbiPromotionTestCase -Name "unit.binding-coverage-qualified-measure-failure" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $inputPath = Join-Path (Get-PbiFailureFixtureInputDirectory -ScenarioName "qualified-measure-in-inputs") "_MOD Promo Qualified Inputs.tmdl"
        $moduleInventory = Get-PbiTmdlInventoryMap -TablePaths @($inputPath)
        $definitions = @(Get-PbiTmdlObjectDefinitions -Path $inputPath)
        $targetInventory = Get-PbiTargetFixtureInventory
        $externalReferences = @(Get-PbiTmdlExternalReferences -Definitions $definitions -ModuleInventory $moduleInventory -TargetInventory $targetInventory)
        $bindingCandidates = @(Get-PbiSimpleBindingCandidates -Definitions $definitions -TargetInventory $targetInventory)

        Assert-PbiEqual -Actual $bindingCandidates.Count -Expected 0 -Message "Did not expect automatic binding candidates for a qualified measure reference."

        $coverageErrors = @(Invoke-PbiPromotionInternal -ScriptBlock {
            param([object[]]$References, [object[]]$Candidates)
            Test-PbiSemanticPromotionBindingCoverage -ExternalReferences $References -BindingCandidates $Candidates
        } -ArgumentList @(,$externalReferences),@(,$bindingCandidates))
        Assert-PbiCondition -Condition (@($coverageErrors | Where-Object { $_ -like "*placeholderizzabili automaticamente*" }).Count -eq 1) -Message "Expected a binding coverage failure for the qualified measure reference."
    }

    $results += Invoke-PbiPromotionTestCase -Name "unit.manifest-generation" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $definitions = @(
            Get-PbiTmdlObjectDefinitions -Path (Join-Path (Get-PbiFixtureInputDirectory -ScenarioName "simple") "_MOD Promo Test Inputs.tmdl")
        )
        $bindingCandidates = @(Get-PbiSimpleBindingCandidates -Definitions $definitions -TargetInventory (Get-PbiTargetFixtureInventory))
        $bindingSummary = @(Invoke-PbiPromotionInternal -ScriptBlock {
            param([object[]]$Candidates)
            Get-PbiBindingSummary -BindingCandidates $Candidates
        } -ArgumentList @(,$bindingCandidates))
        $manifest = Invoke-PbiPromotionInternal -ScriptBlock {
            param([object[]]$Summary)
            Get-PbiGeneratedManifest -ModuleId "promo_fixture_simple" -Version "0.1.0" -Domain "shared" -TableNames @("_MOD Promo Test Inputs", "MOD Promo Test") -BindingSummary $Summary
        } -ArgumentList @(,$bindingSummary)
        $expectedManifest = Get-PbiFixtureExpectedManifest -ScenarioName "simple"

        Assert-PbiEqual -Actual (ConvertTo-PbiNormalizedJson -InputObject $manifest) -Expected (ConvertTo-PbiNormalizedJson -InputObject $expectedManifest) -Message "Generated manifest does not match the golden fixture."
    }

    return @($results)
}

function Invoke-PbiPromotionIntegrationTests {
    param(
        [Parameter(Mandatory = $true)][string]$ArtifactRoot,
        [Parameter(Mandatory = $true)][string]$SourceProjectPath
    )

    $results = @()

    $results += Invoke-PbiPromotionTestCase -Name "integration.delta-classification" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $project = New-PbiPromotionProjectCopy -SourceProjectPath $SourceProjectPath -DestinationRoot (Join-Path $caseRoot "workbench")
        $moduleId = "promo_fixture_simple"

        $null = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "new-promotion-baseline" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            ModuleId      = $moduleId
        }) -LogPath (Join-Path $caseRoot "baseline.log")

        Copy-PbiFixtureTablesToProject -FixtureDirectory (Get-PbiFixtureInputDirectory -ScenarioName "simple") -Project $project
        $delta = Invoke-PbiPromotionInternal -ScriptBlock {
            param($PbipPath, $CurrentModuleId)
            $projectObject = Resolve-PbiConsumerProject -ProjectPath $PbipPath
            $baseline = Get-PbiSemanticPromotionBaseline -Project $projectObject -ModuleId $CurrentModuleId
            Get-PbiSemanticPromotionDelta -Project $projectObject -Baseline $baseline
        } -ArgumentList @($project.PbipPath, $moduleId)

        Assert-PbiEqual -Actual (@($delta.newTables).Count) -Expected 2 -Message "Expected two new tables in the delta."
        Assert-PbiCondition -Condition ((@($delta.newTables) -join "|") -eq "_MOD Promo Test Inputs|MOD Promo Test") -Message "Unexpected new table set in the delta."
        Assert-PbiEqual -Actual (@($delta.modifiedTables).Count) -Expected 0 -Message "Did not expect modified target tables in the delta."
        Assert-PbiEqual -Actual (@($delta.blockedFiles).Count) -Expected 0 -Message "Did not expect blocked files in the delta."
    }

    $results += Invoke-PbiPromotionTestCase -Name "integration.golden-simple-package" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $project = New-PbiPromotionProjectCopy -SourceProjectPath $SourceProjectPath -DestinationRoot (Join-Path $caseRoot "workbench")
        $moduleId = "promo_fixture_simple"
        $outputRoot = Join-Path $caseRoot "output"

        $null = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "new-promotion-baseline" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            ModuleId      = $moduleId
        }) -LogPath (Join-Path $caseRoot "baseline.log")

        Copy-PbiFixtureTablesToProject -FixtureDirectory (Get-PbiFixtureInputDirectory -ScenarioName "simple") -Project $project
        $promotionResult = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "promote-semantic-module" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            Domain        = "shared"
            ModuleId      = $moduleId
            OutputRoot    = $outputRoot
            Force         = $true
        }) -LogPath (Join-Path $caseRoot "promote.log")

        $actualManifest = Read-PbiJsonFile -Path (Join-Path $outputRoot "manifest.json")
        $expectedManifest = Get-PbiFixtureExpectedManifest -ScenarioName "simple"
        Assert-PbiEqual -Actual (ConvertTo-PbiNormalizedJson -InputObject $actualManifest) -Expected (ConvertTo-PbiNormalizedJson -InputObject $expectedManifest) -Message "Promoted manifest does not match the expected simple golden package."

        foreach ($expectedFile in @("_MOD Promo Test Inputs.tmdl", "MOD Promo Test.tmdl")) {
            $actualContent = Get-PbiNormalizedFileContent -Path (Join-Path $outputRoot ("semantic\" + $expectedFile))
            $expectedContent = Get-PbiNormalizedFileContent -Path (Join-Path (Get-PbiFixtureExpectedDirectory -ScenarioName "simple") $expectedFile)
            Assert-PbiEqual -Actual $actualContent -Expected $expectedContent -Message ("Promoted semantic file '{0}' does not match the expected golden output." -f $expectedFile)
        }

        $reportPath = Join-Path $project.ModuleConfigDir ("promotion-sessions\" + $moduleId + "\promotion-report.json")
        $report = Read-PbiJsonFile -Path $reportPath
        Assert-PbiEqual -Actual (@($report.externalReferences).Count) -Expected 2 -Message "Expected two external references in the promotion report."
        Assert-PbiEqual -Actual (@($report.generatedBindings).Count) -Expected 2 -Message "Expected two generated bindings in the promotion report."
        Assert-PbiCondition -Condition (@($report.supportMatrix).Count -ge 4) -Message "Expected the promotion report to include the V1 support matrix."
        Assert-PbiContains -ActualText $promotionResult.OutputText -ExpectedFragment "External bindings: 2" -Message "The promotion CLI output should report the generated binding count."
    }

    $results += Invoke-PbiPromotionTestCase -Name "integration.golden-multi-table-package" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $project = New-PbiPromotionProjectCopy -SourceProjectPath $SourceProjectPath -DestinationRoot (Join-Path $caseRoot "workbench")
        $moduleId = "promo_fixture_multi"
        $outputRoot = Join-Path $caseRoot "output"

        $null = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "new-promotion-baseline" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            ModuleId      = $moduleId
        }) -LogPath (Join-Path $caseRoot "baseline.log")

        Copy-PbiFixtureTablesToProject -FixtureDirectory (Get-PbiFixtureInputDirectory -ScenarioName "multi") -Project $project
        $null = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "promote-semantic-module" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            Domain        = "shared"
            ModuleId      = $moduleId
            OutputRoot    = $outputRoot
            Force         = $true
        }) -LogPath (Join-Path $caseRoot "promote.log")

        $actualManifest = Read-PbiJsonFile -Path (Join-Path $outputRoot "manifest.json")
        $expectedManifest = Get-PbiFixtureExpectedManifest -ScenarioName "multi"
        Assert-PbiEqual -Actual (ConvertTo-PbiNormalizedJson -InputObject $actualManifest) -Expected (ConvertTo-PbiNormalizedJson -InputObject $expectedManifest) -Message "Promoted manifest does not match the expected multi-table golden package."
        Assert-PbiEqual -Actual (@($actualManifest.provides.semanticTables).Count) -Expected 3 -Message "Expected three semantic tables in the multi-table manifest."
        Assert-PbiEqual -Actual (@($actualManifest.semanticUx.hiddenTables).Count) -Expected 2 -Message "Expected two hidden technical tables in the multi-table manifest."
    }

    $results += Invoke-PbiPromotionTestCase -Name "integration.failure-target-owned-change" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $project = New-PbiPromotionProjectCopy -SourceProjectPath $SourceProjectPath -DestinationRoot (Join-Path $caseRoot "workbench")
        $moduleId = "promo_failure_target"

        $null = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "new-promotion-baseline" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            ModuleId      = $moduleId
        }) -LogPath (Join-Path $caseRoot "baseline.log")

        Add-Content -Path (Join-Path $project.SemanticModelPath "definition\tables\Sales.tmdl") -Value ([Environment]::NewLine + "annotation PromotionTest = 1")
        $failure = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "promote-semantic-module" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            Domain        = "shared"
            ModuleId      = $moduleId
            OutputRoot    = (Join-Path $caseRoot "output")
            Force         = $true
        }) -LogPath (Join-Path $caseRoot "promote.log") -ExpectFailure

        Assert-PbiContains -ActualText $failure.OutputText -ExpectedFragment "Hai modificato una tabella target-owned: Sales." -Message "Expected a target-owned table failure message."
    }

    $results += Invoke-PbiPromotionTestCase -Name "integration.failure-relationships-change" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $project = New-PbiPromotionProjectCopy -SourceProjectPath $SourceProjectPath -DestinationRoot (Join-Path $caseRoot "workbench")
        $moduleId = "promo_failure_relationships"

        $null = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "new-promotion-baseline" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            ModuleId      = $moduleId
        }) -LogPath (Join-Path $caseRoot "baseline.log")

        Add-Content -Path (Join-Path $project.SemanticModelPath "definition\relationships.tmdl") -Value ([Environment]::NewLine + "annotation PromotionTest = 1")
        $failure = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "promote-semantic-module" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            Domain        = "shared"
            ModuleId      = $moduleId
            OutputRoot    = (Join-Path $caseRoot "output")
            Force         = $true
        }) -LogPath (Join-Path $caseRoot "promote.log") -ExpectFailure

        Assert-PbiContains -ActualText $failure.OutputText -ExpectedFragment "Hai toccato relationships.tmdl, non supportato nel V1." -Message "Expected a relationships failure message."
    }

    $results += Invoke-PbiPromotionTestCase -Name "integration.failure-strict-outside-inputs" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $project = New-PbiPromotionProjectCopy -SourceProjectPath $SourceProjectPath -DestinationRoot (Join-Path $caseRoot "workbench")
        $moduleId = "promo_failure_strict"

        $null = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "new-promotion-baseline" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            ModuleId      = $moduleId
        }) -LogPath (Join-Path $caseRoot "baseline.log")

        Copy-PbiFixtureTablesToProject -FixtureDirectory (Get-PbiFailureFixtureInputDirectory -ScenarioName "strict-outside-inputs") -Project $project
        $failure = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "promote-semantic-module" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            Domain        = "shared"
            ModuleId      = $moduleId
            OutputRoot    = (Join-Path $caseRoot "output")
            Force         = $true
        }) -LogPath (Join-Path $caseRoot "promote.log") -ExpectFailure

        Assert-PbiContains -ActualText $failure.OutputText -ExpectedFragment "fuori dal layer Inputs consentito" -Message "Expected strict-mode failure for an external reference outside the Inputs layer."
    }

    $results += Invoke-PbiPromotionTestCase -Name "integration.failure-qualified-measure-in-inputs" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $project = New-PbiPromotionProjectCopy -SourceProjectPath $SourceProjectPath -DestinationRoot (Join-Path $caseRoot "workbench")
        $moduleId = "promo_failure_qualified_measure"

        $null = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "new-promotion-baseline" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            ModuleId      = $moduleId
        }) -LogPath (Join-Path $caseRoot "baseline.log")

        Copy-PbiFixtureTablesToProject -FixtureDirectory (Get-PbiFailureFixtureInputDirectory -ScenarioName "qualified-measure-in-inputs") -Project $project
        $failure = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "promote-semantic-module" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            Domain        = "shared"
            ModuleId      = $moduleId
            OutputRoot    = (Join-Path $caseRoot "output")
            Force         = $true
        }) -LogPath (Join-Path $caseRoot "promote.log") -ExpectFailure

        Assert-PbiContains -ActualText $failure.OutputText -ExpectedFragment "placeholderizzabili automaticamente" -Message "Expected strict-mode failure for a qualified measure reference inside Inputs."
    }

    $results += Invoke-PbiPromotionTestCase -Name "integration.idempotence" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $project = New-PbiPromotionProjectCopy -SourceProjectPath $SourceProjectPath -DestinationRoot (Join-Path $caseRoot "workbench")
        $moduleId = "promo_fixture_simple"
        $run1Root = Join-Path $caseRoot "run1"
        $run2Root = Join-Path $caseRoot "run2"

        $null = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "new-promotion-baseline" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            ModuleId      = $moduleId
        }) -LogPath (Join-Path $caseRoot "baseline.log")

        Copy-PbiFixtureTablesToProject -FixtureDirectory (Get-PbiFixtureInputDirectory -ScenarioName "simple") -Project $project
        $null = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "promote-semantic-module" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            Domain        = "shared"
            ModuleId      = $moduleId
            OutputRoot    = $run1Root
            Force         = $true
        }) -LogPath (Join-Path $caseRoot "promote-run1.log")

        $null = Invoke-PbiModularityCommand -ScriptPath $invokeModularityScript -CommandName "promote-semantic-module" -Parameters ([ordered]@{
            WorkspaceRoot = $resolvedWorkspaceRoot
            ProjectPath   = $project.PbipPath
            Domain        = "shared"
            ModuleId      = $moduleId
            OutputRoot    = $run2Root
            Force         = $true
        }) -LogPath (Join-Path $caseRoot "promote-run2.log")

        $filesRun1 = @(Get-ChildItem -Path $run1Root -Recurse -File | Sort-Object FullName)
        $filesRun2 = @(Get-ChildItem -Path $run2Root -Recurse -File | Sort-Object FullName)
        Assert-PbiEqual -Actual $filesRun1.Count -Expected $filesRun2.Count -Message "Idempotence check found a different file count between runs."

        for ($index = 0; $index -lt $filesRun1.Count; $index++) {
            $relativeRun1 = Get-PbiRelativePath -BasePath $run1Root -Path $filesRun1[$index].FullName
            $relativeRun2 = Get-PbiRelativePath -BasePath $run2Root -Path $filesRun2[$index].FullName
            Assert-PbiEqual -Actual $relativeRun1 -Expected $relativeRun2 -Message "Idempotence check found a different file layout between runs."
            $hashRun1 = (Get-FileHash -Path $filesRun1[$index].FullName -Algorithm SHA256).Hash
            $hashRun2 = (Get-FileHash -Path $filesRun2[$index].FullName -Algorithm SHA256).Hash
            Assert-PbiEqual -Actual $hashRun1 -Expected $hashRun2 -Message ("Idempotence check found different content for '{0}'." -f $relativeRun1)
        }
    }

    $results += Invoke-PbiPromotionTestCase -Name "integration.roundtrip-install" -ArtifactRoot $ArtifactRoot -Action {
        param($caseRoot)

        $sandboxRoot = Join-Path $caseRoot "sandbox"
        $sandboxWorkspaceRoot = $sandboxRoot
        $sandboxModularityRoot = Join-Path $sandboxWorkspaceRoot "modularity"
        $sandboxWorkbenchRoot = Join-Path $sandboxWorkspaceRoot "consumer\workbench"
        $sandboxInstallTargetRoot = Join-Path $sandboxWorkspaceRoot "consumer\install-target"
        Ensure-PbiEmptyDirectory -Path $sandboxWorkspaceRoot
        Copy-PbiDirectoryContents -SourceRoot $resolvedWorkspaceRoot -DestinationRoot $sandboxModularityRoot -ExcludeNames @(".git")

        $workbenchProject = New-PbiPromotionProjectCopy -SourceProjectPath $SourceProjectPath -DestinationRoot $sandboxWorkbenchRoot
        $installTargetProject = New-PbiPromotionProjectCopy -SourceProjectPath $SourceProjectPath -DestinationRoot $sandboxInstallTargetRoot
        $moduleId = "promo_fixture_roundtrip"
        $sandboxInvokeModularityScript = Join-Path $sandboxModularityRoot "pbi-modular-platform\Invoke-PbiModularity.ps1"

        $null = Invoke-PbiModularityCommand -ScriptPath $sandboxInvokeModularityScript -CommandName "new-promotion-baseline" -Parameters ([ordered]@{
            WorkspaceRoot = $sandboxWorkspaceRoot
            ProjectPath   = $workbenchProject.PbipPath
            ModuleId      = $moduleId
        }) -LogPath (Join-Path $caseRoot "roundtrip-baseline.log")

        Copy-PbiFixtureTablesToProject -FixtureDirectory (Get-PbiFixtureInputDirectory -ScenarioName "simple") -Project $workbenchProject
        $null = Invoke-PbiModularityCommand -ScriptPath $sandboxInvokeModularityScript -CommandName "promote-semantic-module" -Parameters ([ordered]@{
            WorkspaceRoot = $sandboxWorkspaceRoot
            ProjectPath   = $workbenchProject.PbipPath
            Domain        = "shared"
            ModuleId      = $moduleId
            Force         = $true
        }) -LogPath (Join-Path $caseRoot "roundtrip-promote.log")

        $null = Invoke-PbiModularityCommand -ScriptPath $sandboxInvokeModularityScript -CommandName "test" -Parameters ([ordered]@{
            WorkspaceRoot = $sandboxWorkspaceRoot
            Domain        = "shared"
            ModuleId      = $moduleId
        }) -LogPath (Join-Path $caseRoot "roundtrip-test-module.log")

        $null = Invoke-PbiModularityCommand -ScriptPath $sandboxInvokeModularityScript -CommandName "validate" -Parameters ([ordered]@{
            WorkspaceRoot        = $sandboxWorkspaceRoot
            ProjectPath          = $installTargetProject.PbipPath
            Domain               = "shared"
            ModuleId             = $moduleId
            AcceptSuggested      = $true
            SaveBindingProfileAs = "roundtrip_auto"
        }) -LogPath (Join-Path $caseRoot "roundtrip-validate.log")

        $installResult = Invoke-PbiModularityCommand -ScriptPath $sandboxInvokeModularityScript -CommandName "install" -Parameters ([ordered]@{
            WorkspaceRoot    = $sandboxWorkspaceRoot
            ProjectPath      = $installTargetProject.PbipPath
            Domain           = "shared"
            ModuleId         = $moduleId
            BindingProfileId = "roundtrip_auto"
        }) -LogPath (Join-Path $caseRoot "roundtrip-install.log")

        $null = Invoke-PbiModularityCommand -ScriptPath $sandboxInvokeModularityScript -CommandName "test" -Parameters ([ordered]@{
            WorkspaceRoot = $sandboxWorkspaceRoot
            ProjectPath   = $installTargetProject.PbipPath
        }) -LogPath (Join-Path $caseRoot "roundtrip-test-project.log")

        Assert-PbiContains -ActualText $installResult.OutputText -ExpectedFragment "Installed module" -Message "Round-trip install output should confirm module installation."
    }

    return @($results)
}

$resolvedProjectPath = Resolve-PbiPromotionTestProjectPath -WorkspaceRoot $resolvedWorkspaceRoot -ProjectPath $ProjectPath

if (-not $OutputRoot) {
    $OutputRoot = Join-Path $scriptRoot ("evidence\" + (Get-PbiTimestampKey))
}

$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
Ensure-PbiEmptyDirectory -Path $OutputRoot

$results = @()
$results += @(Invoke-PbiPromotionUnitTests -ArtifactRoot (Join-Path $OutputRoot "unit"))

if ($resolvedProjectPath) {
    $results += @(Invoke-PbiPromotionIntegrationTests -ArtifactRoot (Join-Path $OutputRoot "integration") -SourceProjectPath $resolvedProjectPath)
}
else {
    $results += (New-PbiQualityResult -Scope "PromotionTest" -Target "integration.skipped" -RuleId "promotion.test.skipped" -Severity "Info" -Message "Integration tests skipped because no source PBIP project was resolved." -Path $OutputRoot)
}

Write-PbiPromotionTestSummaryFiles -OutputRoot $OutputRoot -Results $results
Show-PbiPromotionTestResults -Results $results

if (-not $KeepArtifacts) {
    $scratchPaths = @(
        Join-Path $OutputRoot "integration\integration.roundtrip-install\sandbox"
    )
    foreach ($scratchPath in $scratchPaths) {
        if (Test-Path $scratchPath) {
            Remove-Item -Path $scratchPath -Recurse -Force
        }
    }
}

if (Test-PbiQualityHasErrors -Results $results) {
    exit 1
}
