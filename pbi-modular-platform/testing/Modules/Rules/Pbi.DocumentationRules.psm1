function Get-PbiMarkdownHeadings {
    param([Parameter(Mandatory = $true)][string]$Path)

    $headings = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($line in @(Get-Content -LiteralPath $Path)) {
        if ($line -match '^##\s+(.+?)\s*$') {
            [void]$headings.Add($Matches[1].Trim())
        }
    }

    return $headings
}

function Get-PbiMarkdownHeadingSequence {
    param([Parameter(Mandatory = $true)][string]$Path)

    $headings = New-Object System.Collections.Generic.List[string]
    foreach ($line in @(Get-Content -LiteralPath $Path)) {
        if ($line -match '^##\s+(.+?)\s*$') {
            $headings.Add($Matches[1].Trim())
        }
    }

    return $headings.ToArray()
}

function Get-PbiMissingMarkdownHeadings {
    param(
        [Parameter(Mandatory = $true)]$Headings,
        [Parameter(Mandatory = $true)][string[]]$RequiredHeadings
    )

    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($requiredHeading in $RequiredHeadings) {
        if (-not $Headings.Contains($requiredHeading)) {
            $missing.Add($requiredHeading)
        }
    }

    return $missing.ToArray()
}

function Test-PbiDocumentationPlaceholderContent {
    param([AllowNull()][string]$Content)

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $false
    }

    return ($Content -match '\[TODO\]') -or
        ($Content -match 'Module scaffold generated for `') -or
        ($Content -match 'TODO: describe module')
}

function Test-PbiExactHeadingSequence {
    param(
        [Parameter(Mandatory = $true)][string[]]$ActualHeadings,
        [Parameter(Mandatory = $true)][string[]]$ExpectedHeadings
    )

    if ($ActualHeadings.Count -ne $ExpectedHeadings.Count) {
        return $false
    }

    for ($index = 0; $index -lt $ExpectedHeadings.Count; $index++) {
        if (-not $ActualHeadings[$index].Equals($ExpectedHeadings[$index], [System.StringComparison]::OrdinalIgnoreCase)) {
            return $false
        }
    }

    return $true
}

function Invoke-PbiModuleDocumentationRules {
    param([Parameter(Mandatory = $true)]$Module)

    $results = New-Object System.Collections.Generic.List[object]
    $scope = "Module"
    $target = $Module.ModuleId

    $readmePath = Join-Path $Module.PackageRoot "README.md"
    if (-not (Test-Path $readmePath)) {
        $results.Add((New-PbiQualityResult -Scope $scope -Target $target -RuleId "module.documentation.readme.exists" -Severity "Error" -Message "README.md is missing." -Path $readmePath))
    }
    else {
        $readmeContent = [string](Get-Content -LiteralPath $readmePath -Raw)
        if ([string]::IsNullOrWhiteSpace($readmeContent)) {
            $results.Add((New-PbiQualityResult -Scope $scope -Target $target -RuleId "module.documentation.readme.nonempty" -Severity "Error" -Message "README.md is empty." -Path $readmePath))
        }
        elseif (Test-PbiDocumentationPlaceholderContent -Content $readmeContent) {
            $results.Add((New-PbiQualityResult -Scope $scope -Target $target -RuleId "module.documentation.readme.placeholder.forbidden" -Severity "Error" -Message "README.md still contains scaffold placeholders or TODO markers." -Path $readmePath))
        }

        if ($readmeContent -match '<!-- PBI_PACKAGE_README_STANDARD_V1 -->') {
            $readmeHeadings = Get-PbiMarkdownHeadings -Path $readmePath
            $readmeHeadingSequence = @(Get-PbiMarkdownHeadingSequence -Path $readmePath)
            $requiredReadmeHeadings = @(
                "Cos'e questo modulo",
                "Cosa fa",
                "Cosa fornisce",
                "Quando utilizzarlo",
                "Requisiti",
                "Quando non utilizzarlo",
                "Installazione rapida"
            )
            $missingReadmeHeadings = @(Get-PbiMissingMarkdownHeadings -Headings $readmeHeadings -RequiredHeadings $requiredReadmeHeadings)
            if ($missingReadmeHeadings.Count -gt 0) {
                $results.Add((New-PbiQualityResult -Scope $scope -Target $target -RuleId "module.documentation.readme.sections.required" -Severity "Error" -Message ("README.md is missing required standard sections: {0}." -f ($missingReadmeHeadings -join ", ")) -Path $readmePath))
            }
            elseif (-not (Test-PbiExactHeadingSequence -ActualHeadings $readmeHeadingSequence -ExpectedHeadings $requiredReadmeHeadings)) {
                $results.Add((New-PbiQualityResult -Scope $scope -Target $target -RuleId "module.documentation.readme.structure.standard" -Severity "Error" -Message ("README.md must keep the exact standard section order. Expected: {0}. Actual: {1}." -f ($requiredReadmeHeadings -join " > "), ($readmeHeadingSequence -join " > ")) -Path $readmePath))
            }
        }
    }

    $packageDocPath = Join-Path $Module.PackageRoot "PACKAGE.md"
    if (-not (Test-Path $packageDocPath)) {
        $results.Add((New-PbiQualityResult -Scope $scope -Target $target -RuleId "module.documentation.package.exists" -Severity "Error" -Message "PACKAGE.md is missing." -Path $packageDocPath))
    }
    else {
        $packageDocContent = [string](Get-Content -LiteralPath $packageDocPath -Raw)
        if ([string]::IsNullOrWhiteSpace($packageDocContent)) {
            $results.Add((New-PbiQualityResult -Scope $scope -Target $target -RuleId "module.documentation.package.nonempty" -Severity "Error" -Message "PACKAGE.md is empty." -Path $packageDocPath))
        }
        elseif (Test-PbiDocumentationPlaceholderContent -Content $packageDocContent) {
            $results.Add((New-PbiQualityResult -Scope $scope -Target $target -RuleId "module.documentation.package.placeholder.forbidden" -Severity "Error" -Message "PACKAGE.md still contains scaffold placeholders or TODO markers." -Path $packageDocPath))
        }

        $packageHeadings = Get-PbiMarkdownHeadings -Path $packageDocPath
        $packageHeadingSequence = @(Get-PbiMarkdownHeadingSequence -Path $packageDocPath)
        $requiredPackageHeadings = @(
            "Identita",
            "Caratteristiche",
            "Cosa installa",
            "Prerequisiti dichiarati",
            "Parametri di binding",
            "Cosa non fa",
            "Installazione corretta",
            "Uso consigliato",
            "File del package"
        )
        $missingPackageHeadings = @(Get-PbiMissingMarkdownHeadings -Headings $packageHeadings -RequiredHeadings $requiredPackageHeadings)
        if ($missingPackageHeadings.Count -gt 0) {
            $results.Add((New-PbiQualityResult -Scope $scope -Target $target -RuleId "module.documentation.package.sections.required" -Severity "Error" -Message ("PACKAGE.md is missing required sections: {0}." -f ($missingPackageHeadings -join ", ")) -Path $packageDocPath))
        }
        elseif (-not (Test-PbiExactHeadingSequence -ActualHeadings $packageHeadingSequence -ExpectedHeadings $requiredPackageHeadings)) {
            $results.Add((New-PbiQualityResult -Scope $scope -Target $target -RuleId "module.documentation.package.structure.standard" -Severity "Error" -Message ("PACKAGE.md must keep the exact standard section order. Expected: {0}. Actual: {1}." -f ($requiredPackageHeadings -join " > "), ($packageHeadingSequence -join " > ")) -Path $packageDocPath))
        }
    }

    return $results.ToArray()
}

Export-ModuleMember -Function Invoke-PbiModuleDocumentationRules
