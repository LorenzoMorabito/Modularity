Set-StrictMode -Version Latest

function Invoke-PbiSemanticPromotionStage {
    param(
        [Parameter(Mandatory = $true)][string]$StageName,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    try {
        return (& $Action)
    }
    catch {
        $message = if ($_.Exception -and -not [string]::IsNullOrWhiteSpace($_.Exception.Message)) {
            $_.Exception.Message
        }
        else {
            "unexpected promotion failure"
        }

        throw ("Promotion stage '{0}' failed. {1}" -f $StageName, $message)
    }
}

function ConvertTo-PbiSemanticPromotionManifestObject {
    param([Parameter(Mandatory = $true)]$Manifest)

    return ($Manifest | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100)
}

function Get-PbiSemanticPromotionReferenceReasonLabel {
    param([string]$SupportReason)

    switch ($SupportReason) {
        "qualified-column-reference" { return "riferimento qualificato a colonna" }
        "qualified-measure-reference" { return "riferimento qualificato a misura" }
        "unqualified-measure-reference" { return "riferimento semplice a misura" }
        "ambiguous-unqualified-measure-reference" { return "riferimento ambiguo a misura con piu owner possibili" }
        "table-reference" { return "riferimento tabellare esterno" }
        "target-object-not-found" { return "oggetto target non trovato" }
        "unresolved-unqualified-reference" { return "riferimento non qualificato non risolto" }
        "unresolved-table-reference" { return "tabella esterna non risolta" }
        default { return "pattern non classificato" }
    }
}

function Get-PbiSemanticPromotionSupportMatrix {
    return @(
        [PSCustomObject]@{
            status  = "supported"
            pattern = "Simple external measure pass-through"
            example = "[Sales LE]"
            notes   = "Solo nel layer _MOD ... Inputs e solo se il nome misura e univoco nel target."
        }
        [PSCustomObject]@{
            status  = "supported"
            pattern = "Simple external column selector"
            example = "SELECTEDVALUE(Corporation[Corporation])"
            notes   = "Supportati anche VALUES e DISTINCT nel layer _MOD ... Inputs."
        }
        [PSCustomObject]@{
            status  = "blocked"
            pattern = "Qualified external measure reference"
            example = "Sales[Sales LE]"
            notes   = "Nel V1 strict il promotore non genera placeholder automatici per questo pattern."
        }
        [PSCustomObject]@{
            status  = "blocked"
            pattern = "External table reference"
            example = "ALL(Sales)"
            notes   = "I riferimenti tabellari esterni non vengono placeholderizzati automaticamente nel V1."
        }
        [PSCustomObject]@{
            status  = "blocked"
            pattern = "Ambiguous unqualified measure reference"
            example = "[Sales LE]"
            notes   = "Se il target contiene piu misure con lo stesso nome, la promotion fallisce."
        }
    )
}

function New-PbiSemanticPromotionBaseline {
    param(
        [string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$ModuleId
    )

    $project = Resolve-PbiConsumerProject -ProjectPath $ProjectPath
    $baseline = New-PbiSemanticPromotionBaselineRecord -Project $project -ModuleId $ModuleId
    $baselinePath = Get-PbiSemanticPromotionBaselinePath -Project $project -ModuleId $ModuleId

    Ensure-PbiDirectory -Path (Split-Path -Parent $baselinePath)
    Write-PbiJsonFile -Path $baselinePath -InputObject $baseline

    return [PSCustomObject]@{
        ModuleId      = $ModuleId
        BaselinePath  = $baselinePath
        WorkbenchMode = $baseline.workbenchMode
        TableCount    = @($baseline.tables).Count
    }
}

function Get-PbiSemanticPromotionBaseline {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)][string]$ModuleId
    )

    $baselinePath = Get-PbiSemanticPromotionBaselinePath -Project $Project -ModuleId $ModuleId
    if (-not (Test-Path $baselinePath)) {
        throw "Promotion baseline '$baselinePath' was not found. Run new-promotion-baseline before authoring."
    }

    return (Read-PbiJsonFile -Path $baselinePath)
}

function Get-PbiSemanticPromotionDelta {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Baseline
    )

    $baselineTableMap = @{}
    foreach ($entry in @($Baseline.tables)) {
        $baselineTableMap[[string]$entry.tableName] = [string]$entry.sha256
    }

    $currentTableMap = @{}
    foreach ($file in (Get-PbiSemanticPromotionTableFiles -Project $Project)) {
        $tableName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $currentTableMap[$tableName] = (Get-PbiFileSha256 -Path $file.FullName)
    }

    $newTables = @($currentTableMap.Keys | Where-Object { -not $baselineTableMap.ContainsKey($_) } | Sort-Object)
    $modifiedTables = @($baselineTableMap.Keys | Where-Object { $currentTableMap.ContainsKey($_) -and ($currentTableMap[$_] -ne $baselineTableMap[$_]) } | Sort-Object)
    $removedTables = @($baselineTableMap.Keys | Where-Object { -not $currentTableMap.ContainsKey($_) } | Sort-Object)

    $blockedFiles = New-Object System.Collections.Generic.List[string]
    foreach ($entry in @($Baseline.trackedGlobalFiles)) {
        $absolutePath = Join-Path $Project.ProjectRoot ([string]$entry.relativePath)
        $currentHash = Get-PbiFileSha256 -Path $absolutePath
        if ($currentHash -ne [string]$entry.sha256) {
            $blockedFiles.Add([string]$entry.relativePath)
        }
    }

    return [PSCustomObject]@{
        newTables      = @($newTables)
        modifiedTables = @($modifiedTables)
        removedTables  = @($removedTables)
        blockedFiles   = @($blockedFiles | Sort-Object -Unique)
    }
}

function Test-PbiSemanticPromotionNaming {
    param([AllowEmptyCollection()][string[]]$TableNames = @())

    $errors = New-Object System.Collections.Generic.List[string]
    if (@($TableNames).Count -eq 0) {
        return @()
    }

    $facadeTables = @($TableNames | Where-Object { $_ -like "MOD *" })
    $unexpectedTables = @($TableNames | Where-Object { ($_ -notlike "MOD *") -and ($_ -notlike "_MOD *") })

    if ($unexpectedTables.Count -gt 0) {
        foreach ($name in $unexpectedTables) {
            $errors.Add(("La tabella nuova '{0}' non rispetta il naming V1 MOD/_MOD." -f $name))
        }
    }

    if ($facadeTables.Count -ne 1) {
        $errors.Add("Il V1 richiede esattamente una facade table business-facing con prefisso 'MOD '.")
    }

    return @($errors)
}

function Get-PbiSemanticPromotionTargetInventory {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Baseline
    )

    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($entry in @($Baseline.tables)) {
        $paths.Add((Get-PbiSemanticPromotionProjectTablePath -Project $Project -TableName ([string]$entry.tableName)))
    }

    return (Get-PbiTmdlInventoryMap -TablePaths @($paths))
}

function Get-PbiSemanticPromotionModuleInventory {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)][string[]]$TableNames
    )

    $paths = @($TableNames | ForEach-Object { Get-PbiSemanticPromotionProjectTablePath -Project $Project -TableName $_ })
    return (Get-PbiTmdlInventoryMap -TablePaths $paths)
}

function Get-PbiSemanticPromotionDefinitions {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)][string[]]$TableNames
    )

    $definitions = @()
    foreach ($tableName in @($TableNames)) {
        $path = Get-PbiSemanticPromotionProjectTablePath -Project $Project -TableName $tableName
        foreach ($definition in (Get-PbiTmdlObjectDefinitions -Path $path)) {
            $definitions += $definition
        }
    }

    return @($definitions)
}

function Test-PbiSemanticPromotionStrictReferences {
    param([Parameter(Mandatory = $true)][object[]]$ExternalReferences)

    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($reference in @($ExternalReferences)) {
        $reasonLabel = Get-PbiSemanticPromotionReferenceReasonLabel -SupportReason $reference.supportReason
        if ($reference.supportStatus -eq "unsupported") {
            $errors.Add(("Il riferimento esterno {0} in {1} non e supportato automaticamente nel V1 ({2})." -f $reference.referenceText, $reference.location, $reasonLabel))
        }

        if ($reference.supportStatus -eq "manual-review") {
            $errors.Add(("Il riferimento esterno {0} in {1} richiede review manuale e non e deterministico nel V1 strict ({2})." -f $reference.referenceText, $reference.location, $reasonLabel))
        }

        if (
            ($reference.supportStatus -eq "supported") -and
            (-not (Test-PbiInputTableName -TableName $reference.tableName))
        ) {
            $errors.Add(("Il riferimento esterno {0} e stato trovato fuori dal layer Inputs consentito in {1}." -f $reference.referenceText, $reference.location))
        }
    }

    return @($errors | Sort-Object -Unique)
}

function Test-PbiSemanticPromotionBindingCoverage {
    param(
        [Parameter(Mandatory = $true)][object[]]$ExternalReferences,
        [AllowEmptyCollection()][object[]]$BindingCandidates = @()
    )

    $candidateObjects = New-Object System.Collections.Generic.List[object]
    foreach ($candidate in @($BindingCandidates)) {
        if ($null -eq $candidate) {
            continue
        }

        if ($candidate -is [System.Array]) {
            foreach ($innerCandidate in @($candidate)) {
                if ($null -ne $innerCandidate) {
                    $candidateObjects.Add($innerCandidate)
                }
            }

            continue
        }

        $candidateObjects.Add($candidate)
    }

    $coveredOriginalTexts = @(
        $candidateObjects |
            Where-Object { $_.PSObject.Properties["originalText"] } |
            ForEach-Object { [string]$_.originalText } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Sort-Object -Unique
    )
    $errors = New-Object System.Collections.Generic.List[string]

    foreach ($reference in @($ExternalReferences | Where-Object { $_.supportStatus -eq "supported" })) {
        if ($coveredOriginalTexts -contains $reference.referenceText) {
            continue
        }

        $reasonLabel = Get-PbiSemanticPromotionReferenceReasonLabel -SupportReason $reference.supportReason
        $errors.Add(("Il riferimento esterno {0} in {1} e stato rilevato ma non rientra nei pattern placeholderizzabili automaticamente del V1 strict ({2})." -f $reference.referenceText, $reference.location, $reasonLabel))
    }

    return @($errors | Sort-Object -Unique)
}

function Get-PbiBindingSummary {
    param([AllowEmptyCollection()][object[]]$BindingCandidates = @())

    $summary = @()
    foreach ($group in @($BindingCandidates | Group-Object bindingKey)) {
        $candidate = $group.Group | Select-Object -First 1
        $summary += [PSCustomObject]@{
            bindingKey      = $candidate.bindingKey
            kind            = $candidate.kind
            targetReference = $candidate.targetReference
            label           = $candidate.label
            description     = $candidate.description
            defaultValue    = $candidate.defaultValue
            roleId          = $candidate.roleId
        }
    }

    return @($summary | Sort-Object kind, bindingKey)
}

function Convert-PbiTextWithPromotionBindings {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][object[]]$BindingCandidates
    )

    $updated = $Content
    foreach ($candidate in @($BindingCandidates | Sort-Object { $_.originalText.Length } -Descending)) {
        if ($candidate.kind -eq "measure") {
            $pattern = [regex]::Escape("[" + $candidate.targetReference + "]")
            $updated = [regex]::Replace($updated, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $candidate.replacementText })
            continue
        }

        if ($candidate.kind -eq "column") {
            $targetRef = $candidate.targetReference
            $tableName = $targetRef.Substring(0, $targetRef.IndexOf("["))
            $qualifiedPattern = [regex]::Escape($targetRef)
            $updated = [regex]::Replace($updated, $qualifiedPattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $candidate.replacementText })

            $tablePattern = "(?i)(?<fn>\bALL\b|\bALLSELECTED\b|\bREMOVEFILTERS\b|\bFILTER\b|\bADDCOLUMNS\b|\bSELECTCOLUMNS\b|\bCOUNTROWS\b|\bSUMX\b|\bAVERAGEX\b|\bMAXX\b|\bMINX\b|\bTOPN\b|\bCALCULATETABLE\b|\bKEEPFILTERS\b|\bSUMMARIZE\b|\bALLEXCEPT\b)\s*\(\s*" + [regex]::Escape($tableName) + "\s*(?=[,\)])"
            $updated = [regex]::Replace($updated, $tablePattern, ("`${fn}(" + $candidate.bindingTable))
        }
    }

    return $updated
}

function Get-PbiGeneratedBindingContract {
    param([AllowEmptyCollection()][object[]]$BindingSummary = @())

    $roles = @()
    foreach ($binding in @($BindingSummary)) {
        $roles += [PSCustomObject]@{
            id           = $binding.roleId
            bindingKey   = $binding.bindingKey
            kind         = $binding.kind
            required     = $true
            label        = $binding.label
            description  = $binding.description
            defaultValue = $binding.defaultValue
            suggestions  = @($binding.defaultValue)
        }
    }

    return [ordered]@{
        mode  = "guided"
        roles = @($roles)
    }
}

function Get-PbiGeneratedManifest {
    param(
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [Parameter(Mandatory = $true)][string]$Version,
        [Parameter(Mandatory = $true)][string]$Domain,
        [Parameter(Mandatory = $true)][string[]]$TableNames,
        [AllowEmptyCollection()][object[]]$BindingSummary = @()
    )

    $primaryTable = @($TableNames | Where-Object { $_ -like "MOD *" })[0]
    $hiddenTables = @($TableNames | Where-Object { $_ -ne $primaryTable } | Sort-Object)
    $measureBindings = @($BindingSummary | Where-Object { $_.kind -eq "measure" } | ForEach-Object { $_.bindingKey })
    $columnBindings = @($BindingSummary | Where-Object { $_.kind -eq "column" } | ForEach-Object { $_.bindingKey })

    $manifest = [ordered]@{
        moduleId       = $ModuleId
        version        = $Version
        domain         = $Domain
        type           = "semantic"
        classification = "semantic-light"
        dependencies   = [ordered]@{
            modules      = @()
            capabilities = @()
        }
        semanticImpact = "additive"
        status         = "prototype"
        description    = ("Promoted semantic module '{0}' from a Power BI Desktop workbench." -f $ModuleId)
        requires       = [ordered]@{
            coreMeasures = @($measureBindings)
            coreColumns  = @($columnBindings)
        }
        provides       = [ordered]@{
            semanticTables = @($TableNames)
        }
        semanticUx     = [ordered]@{
            primaryTable = $primaryTable
            hiddenTables = @($hiddenTables)
        }
        bindingContract = $null
    }

    if (@($BindingSummary).Count -gt 0) {
        $manifest["bindingContract"] = (Get-PbiGeneratedBindingContract -BindingSummary $BindingSummary)
    }

    return $manifest
}

function Get-PbiGeneratedReadmeContent {
    param(
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [Parameter(Mandatory = $true)][string[]]$TableNames,
        [AllowEmptyCollection()][object[]]$BindingSummary = @()
    )

    $primaryTable = @($TableNames | Where-Object { $_ -like "MOD *" })[0]
    return @(
        ("# " + $ModuleId),
        "",
        "<!-- PBI_PACKAGE_README_STANDARD_V1 -->",
        "",
        "## Cos'e questo modulo",
        "",
        "Modulo semantic-only promosso da un workbench Power BI Desktop in modalita byPath locale.",
        "",
        "## Cosa fa",
        "",
        ('Installa le tabelle semantic del modulo e mantiene separato il layer di binding verso il target tramite la facade `' + $primaryTable + '`.'),
        "",
        "## Cosa fornisce",
        "",
        ("Fornisce " + @($TableNames).Count + " tabelle semantic package-owned e " + @($BindingSummary).Count + " binding generati automaticamente."),
        "",
        "## Quando utilizzarlo",
        "",
        "Usalo quando hai creato nuove tabelle module-owned in un workbench Desktop e vuoi promuoverle in un package installabile.",
        "",
        "## Requisiti",
        "",
        "Il package richiede un consumer compatibile con i binding generati nel manifest.",
        "",
        "## Quando non utilizzarlo",
        "",
        "Non usarlo se hai modificato tabelle target-owned, relazioni o metadata globali del semantic model.",
        "",
        "## Installazione rapida",
        "",
        '1. esegui `suggest-bindings` e salva il profilo di binding',
        '2. esegui `validate`',
        '3. esegui `install`',
        '4. esegui `test`',
        "",
        'Per dettagli tecnici, limiti V1 e asset installati usare anche `PACKAGE.md`.'
    ) -join [Environment]::NewLine
}

function Get-PbiGeneratedPackageSheetContent {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [AllowEmptyCollection()][object[]]$BindingSummary = @()
    )

    $tableLines = @($Manifest.provides.semanticTables | ForEach-Object { ('- `' + $_ + '`') })
    $bindingLines = if (@($BindingSummary).Count -gt 0) {
        @($BindingSummary | ForEach-Object { '- `{0}` -> `{1}`' -f $_.bindingKey, $_.targetReference })
    }
    else {
        @('- `nessun binding generato`')
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(("# " + $Manifest.moduleId))
    $lines.Add("")
    $lines.Add("<!-- PBI_PACKAGE_SHEET_STANDARD_V1 -->")
    $lines.Add("")
    $lines.Add("## Identita")
    $lines.Add(('- Modulo: `' + $Manifest.moduleId + '`'))
    $lines.Add(('- Dominio: `' + $Manifest.domain + '`'))
    $lines.Add(('- Versione: `' + $Manifest.version + '`'))
    $lines.Add('- Tipo: `semantic`')
    $lines.Add('- Classification: `semantic-light`')
    $lines.Add('- Semantic impact: `additive`')
    $lines.Add('- Stato: `prototype`')
    $lines.Add('- Compatibilita consumer dichiarata: `da validare nel collaudo V1`')
    $lines.Add('- Descrizione: `Package semantic promosso automaticamente da workbench Desktop.`')
    $lines.Add("")
    $lines.Add("## Caratteristiche")
    $lines.Add("- Promotion V1 semantic-only.")
    $lines.Add("- Fail-fast su tabelle target, relazioni e metadata globali fuori perimetro.")
    $lines.Add("- Pattern binding supportati automaticamente: `[Measure]` semplice univoca e selector `SELECTEDVALUE/VALUES/DISTINCT(Table[Column])` nel layer `_MOD ... Inputs`.")
    $lines.Add("")
    $lines.Add("## Cosa installa")
    foreach ($tableLine in $tableLines) {
        $lines.Add($tableLine)
    }
    $lines.Add("")
    $lines.Add("## Prerequisiti dichiarati")
    $lines.Add('- Moduli dipendenti: `nessuno`')
    $lines.Add('- Capability richieste: `nessuna`')
    $lines.Add(('- Core measures richieste: `' + (@($Manifest.requires.coreMeasures) -join ", ") + '`'))
    $lines.Add(('- Core columns richieste: `' + (@($Manifest.requires.coreColumns) -join ", ") + '`'))
    $lines.Add("")
    $lines.Add("## Parametri di binding")
    foreach ($bindingLine in $bindingLines) {
        $lines.Add($bindingLine)
    }
    $lines.Add("")
    $lines.Add("## Cosa non fa")
    $lines.Add("- Non promuove report, visual, bookmark o asset PBIR.")
    $lines.Add("- Non accetta modifiche target-owned o file globali TMDL fuori perimetro.")
    $lines.Add("")
    $lines.Add("## Installazione corretta")
    $lines.Add('- Parametri CLI base: `-ProjectPath`, `-Domain`, `-ModuleId`')
    $lines.Add('- Parametri CLI consigliati per il binding: `-InteractiveUi`, `-SaveBindingProfileAs`, `-BindingProfileId`')
    $lines.Add("")
    $lines.Add("## Uso consigliato")
    $lines.Add("- Validare sempre il package con `test-module` e poi fare smoke-install su un consumer sandbox.")
    $lines.Add("")
    $lines.Add("## File del package")
    $lines.Add('- `manifest.json`: contratto del modulo promosso.')
    $lines.Add('- `README.md`: descrizione business e guida rapida.')
    $lines.Add('- `PACKAGE.md`: scheda installativa operativa del package.')
    $lines.Add('- `semantic/`: tabelle `.tmdl` module-owned esportate dal workbench.')

    return ($lines -join [Environment]::NewLine)
}

function Write-PbiPromotedSemanticPackage {
    param(
        [Parameter(Mandatory = $true)][string]$PackageRoot,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)][string[]]$TableNames,
        [AllowEmptyCollection()][object[]]$BindingCandidates = @(),
        [switch]$Force
    )

    if ((Test-Path $PackageRoot) -and -not $Force) {
        throw "Package root '$PackageRoot' already exists. Use -Force to overwrite."
    }

    if (Test-Path $PackageRoot) {
        Remove-Item -Path $PackageRoot -Recurse -Force
    }

    $semanticRoot = Join-Path $PackageRoot "semantic"
    Ensure-PbiDirectory -Path $semanticRoot

    foreach ($tableName in @($TableNames)) {
        $sourcePath = Get-PbiSemanticPromotionProjectTablePath -Project $Project -TableName $tableName
        $content = Get-Content -Path $sourcePath -Raw
        $renderedContent = Convert-PbiTextWithPromotionBindings -Content $content -BindingCandidates $BindingCandidates
        Write-PbiUtf8File -Path (Join-Path $semanticRoot ($tableName + ".tmdl")) -Content $renderedContent
    }

    $bindingSummary = Get-PbiBindingSummary -BindingCandidates $BindingCandidates
    Write-PbiJsonFile -Path (Join-Path $PackageRoot "manifest.json") -InputObject $Manifest
    Write-PbiUtf8File -Path (Join-Path $PackageRoot "README.md") -Content (Get-PbiGeneratedReadmeContent -ModuleId $Manifest.moduleId -TableNames $TableNames -BindingSummary $bindingSummary)
    Write-PbiUtf8File -Path (Join-Path $PackageRoot "PACKAGE.md") -Content (Get-PbiGeneratedPackageSheetContent -Manifest $Manifest -BindingSummary $bindingSummary)
}

function Invoke-PbiSemanticModulePromotion {
    param(
        [string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Domain,
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [string]$OutputRoot,
        [string]$Version = "0.1.0",
        [switch]$Force
    )

    $resolvedWorkspaceRoot = Get-PbiInstallerWorkspaceRoot -WorkspaceRoot $WorkspaceRoot -ScriptRoot $PSScriptRoot
    $project = Resolve-PbiConsumerProject -ProjectPath $ProjectPath
    $baseline = Get-PbiSemanticPromotionBaseline -Project $project -ModuleId $ModuleId
    $delta = Get-PbiSemanticPromotionDelta -Project $project -Baseline $baseline
    $namingErrors = @(Test-PbiSemanticPromotionNaming -TableNames @($delta.newTables))

    $perimeterErrors = New-Object System.Collections.Generic.List[string]
    foreach ($name in @($delta.modifiedTables)) {
        $perimeterErrors.Add(("Hai modificato una tabella target-owned: {0}." -f $name))
    }

    foreach ($name in @($delta.removedTables)) {
        $perimeterErrors.Add(("Hai rimosso una tabella target-owned: {0}." -f $name))
    }

    foreach ($path in @($delta.blockedFiles)) {
        if ($path -like "*/relationships.tmdl" -or $path -like "*\relationships.tmdl") {
            $perimeterErrors.Add("Hai toccato relationships.tmdl, non supportato nel V1.")
            continue
        }

        $perimeterErrors.Add(("Hai modificato un file fuori perimetro consentito: {0}." -f $path))
    }

    if (@($delta.newTables).Count -eq 0) {
        $perimeterErrors.Add("Non ci sono nuove tabelle module-owned da promuovere.")
    }

    if (($perimeterErrors.Count -gt 0) -or ($namingErrors.Count -gt 0)) {
        throw ((@($perimeterErrors + $namingErrors) -join " "))
    }

    $moduleInventory = Invoke-PbiSemanticPromotionStage -StageName "module-inventory" -Action {
        Get-PbiSemanticPromotionModuleInventory -Project $project -TableNames @($delta.newTables)
    }
    $targetInventory = Invoke-PbiSemanticPromotionStage -StageName "target-inventory" -Action {
        Get-PbiSemanticPromotionTargetInventory -Project $project -Baseline $baseline
    }
    $definitions = @(Invoke-PbiSemanticPromotionStage -StageName "definition-parse" -Action {
        Get-PbiSemanticPromotionDefinitions -Project $project -TableNames @($delta.newTables)
    })
    $externalReferences = @(Invoke-PbiSemanticPromotionStage -StageName "external-reference-scan" -Action {
        Get-PbiTmdlExternalReferences -Definitions $definitions -ModuleInventory $moduleInventory -TargetInventory $targetInventory
    })
    $strictErrors = @(Test-PbiSemanticPromotionStrictReferences -ExternalReferences $externalReferences)
    if ($strictErrors.Count -gt 0) {
        throw (($strictErrors -join " "))
    }

    $bindingCandidates = @(Invoke-PbiSemanticPromotionStage -StageName "binding-discovery" -Action {
        @(Get-PbiSimpleBindingCandidates -Definitions $definitions -TargetInventory $targetInventory)
    })
    $bindingSummary = @(Invoke-PbiSemanticPromotionStage -StageName "binding-summary" -Action {
        @(Get-PbiBindingSummary -BindingCandidates $bindingCandidates)
    })
    $bindingCoverageErrors = @(Invoke-PbiSemanticPromotionStage -StageName "binding-coverage" -Action {
        @(Test-PbiSemanticPromotionBindingCoverage -ExternalReferences $externalReferences -BindingCandidates $bindingCandidates)
    })
    if ($bindingCoverageErrors.Count -gt 0) {
        throw (($bindingCoverageErrors -join " "))
    }
    $manifest = Invoke-PbiSemanticPromotionStage -StageName "manifest-generation" -Action {
        $rawManifest = Get-PbiGeneratedManifest -ModuleId $ModuleId -Version $Version -Domain $Domain -TableNames @($delta.newTables) -BindingSummary $bindingSummary
        ConvertTo-PbiSemanticPromotionManifestObject -Manifest $rawManifest
    }
    $packageRoot = Resolve-PbiSemanticPromotionOutputRoot -WorkspaceRoot $resolvedWorkspaceRoot -Domain $Domain -ModuleId $ModuleId -OutputRoot $OutputRoot

    Invoke-PbiSemanticPromotionStage -StageName "manifest-validation" -Action {
        Test-PbiModuleManifestSchema -Manifest $manifest -ManifestPath (Join-Path $packageRoot "manifest.json")
    }
    Invoke-PbiSemanticPromotionStage -StageName "package-write" -Action {
        Write-PbiPromotedSemanticPackage -PackageRoot $packageRoot -Manifest $manifest -Project $project -TableNames @($delta.newTables) -BindingCandidates $bindingCandidates -Force:$Force
    }
    $catalogRegistration = Invoke-PbiSemanticPromotionStage -StageName "catalog-registration" -Action {
        Register-PbiSemanticPromotionPackageInCatalog -WorkspaceRoot $resolvedWorkspaceRoot -Domain $Domain -Manifest $manifest -PackageRoot $packageRoot
    }

    $reportObject = [ordered]@{
        baselineId         = $baseline.baselineId
        projectId          = $project.ProjectId
        packageRoot        = $packageRoot
        catalogPath        = if ($catalogRegistration) { $catalogRegistration.CatalogPath } else { "" }
        delta              = [ordered]@{
            newTables      = @($delta.newTables)
            modifiedTables = @($delta.modifiedTables)
            removedTables  = @($delta.removedTables)
            blockedFiles   = @($delta.blockedFiles)
        }
        externalReferences = @($externalReferences)
        generatedBindings  = @($bindingSummary)
        supportMatrix      = @(Get-PbiSemanticPromotionSupportMatrix)
    }
    $reportPaths = Invoke-PbiSemanticPromotionStage -StageName "report-write" -Action {
        Write-PbiSemanticPromotionReportFiles -Project $project -ModuleId $ModuleId -ReportObject $reportObject
    }

    return [PSCustomObject]@{
        ModuleId       = $ModuleId
        PackageRoot    = $packageRoot
        CatalogPath    = if ($catalogRegistration) { $catalogRegistration.CatalogPath } else { "" }
        Manifest       = $manifest
        BindingSummary = $bindingSummary
        Report         = [PSCustomObject]@{
            JsonPath     = $reportPaths.JsonPath
            MarkdownPath = $reportPaths.MarkdownPath
        }
    }
}

Export-ModuleMember -Function `
    New-PbiSemanticPromotionBaseline, `
    Invoke-PbiSemanticModulePromotion
