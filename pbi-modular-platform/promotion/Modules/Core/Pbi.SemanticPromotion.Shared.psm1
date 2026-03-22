Set-StrictMode -Version Latest

function Get-PbiSemanticPromotionSessionRoot {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)][string]$ModuleId
    )

    return (Join-Path $Project.ModuleConfigDir ("promotion-sessions\" + $ModuleId))
}

function Get-PbiSemanticPromotionBaselinePath {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)][string]$ModuleId
    )

    return (Join-Path (Get-PbiSemanticPromotionSessionRoot -Project $Project -ModuleId $ModuleId) "baseline.json")
}

function Get-PbiSemanticPromotionReportJsonPath {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)][string]$ModuleId
    )

    return (Join-Path (Get-PbiSemanticPromotionSessionRoot -Project $Project -ModuleId $ModuleId) "promotion-report.json")
}

function Get-PbiSemanticPromotionReportMarkdownPath {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)][string]$ModuleId
    )

    return (Join-Path (Get-PbiSemanticPromotionSessionRoot -Project $Project -ModuleId $ModuleId) "promotion-report.md")
}

function Get-PbiSemanticPromotionDefinitionRoot {
    param([Parameter(Mandatory = $true)]$Project)

    return (Join-Path $Project.SemanticModelPath "definition")
}

function Get-PbiSemanticPromotionTablesRoot {
    param([Parameter(Mandatory = $true)]$Project)

    return (Join-Path (Get-PbiSemanticPromotionDefinitionRoot -Project $Project) "tables")
}

function Get-PbiSemanticPromotionProjectTablePath {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)][string]$TableName
    )

    return (Join-Path (Get-PbiSemanticPromotionTablesRoot -Project $Project) ($TableName + ".tmdl"))
}

function Get-PbiSemanticPromotionTableFiles {
    param([Parameter(Mandatory = $true)]$Project)

    $tablesRoot = Get-PbiSemanticPromotionTablesRoot -Project $Project
    if (-not (Test-Path $tablesRoot)) {
        return @()
    }

    return @(
        Get-ChildItem -Path $tablesRoot -File -Filter "*.tmdl" -ErrorAction SilentlyContinue |
            Sort-Object Name
    )
}

function Get-PbiFileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path -PathType Leaf)) {
        return ""
    }

    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-PbiSemanticPromotionTrackedGlobalFiles {
    param([Parameter(Mandatory = $true)]$Project)

    $definitionRoot = Get-PbiSemanticPromotionDefinitionRoot -Project $Project
    $tracked = New-Object System.Collections.Generic.List[string]

    foreach ($relativePath in @(
        "database.tmdl",
        "expressions.tmdl",
        "model.tmdl",
        "relationships.tmdl"
    )) {
        $tracked.Add((Join-Path $definitionRoot $relativePath))
    }

    $culturesRoot = Join-Path $definitionRoot "cultures"
    if (Test-Path $culturesRoot) {
        foreach ($file in @(Get-ChildItem -Path $culturesRoot -Recurse -File -ErrorAction SilentlyContinue | Sort-Object FullName)) {
            $tracked.Add($file.FullName)
        }
    }

    return @($tracked | Sort-Object -Unique)
}

function Get-PbiTmdlNameFromLine {
    param([Parameter(Mandatory = $true)][string]$Line)

    if ($Line -match "^\s*[A-Za-z]+\s+'((?:[^']|'')+)'") {
        return $matches[1].Replace("''", "'")
    }

    if ($Line -match "^\s*[A-Za-z]+\s+([^\s=]+)") {
        return $matches[1]
    }

    return ""
}

function Get-PbiTmdlTableNameFromFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    foreach ($line in (Get-Content -Path $Path)) {
        if ($line -match "^\s*table\b") {
            return (Get-PbiTmdlNameFromLine -Line $line)
        }
    }

    throw "Table header not found in '$Path'."
}

function Resolve-PbiSemanticPromotionOutputRoot {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Domain,
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [string]$OutputRoot
    )

    if ($OutputRoot) {
        return [System.IO.Path]::GetFullPath($OutputRoot)
    }

    $resolvedWorkspaceRoot = Get-PbiInstallerWorkspaceRoot -WorkspaceRoot $WorkspaceRoot -ScriptRoot $PSScriptRoot
    $modularityRoot = if (Test-Path (Join-Path $resolvedWorkspaceRoot "modularity")) {
        Join-Path $resolvedWorkspaceRoot "modularity"
    }
    else {
        $resolvedWorkspaceRoot
    }

    $domainRoot = Join-Path $modularityRoot ("pbi-" + $Domain + "-domain")
    if (-not (Test-Path $domainRoot)) {
        throw "Domain root '$domainRoot' does not exist."
    }

    return (Join-Path $domainRoot ("packages\" + $ModuleId))
}

function Resolve-PbiSemanticPromotionDomainRoot {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Domain
    )

    $resolvedWorkspaceRoot = Get-PbiInstallerWorkspaceRoot -WorkspaceRoot $WorkspaceRoot -ScriptRoot $PSScriptRoot
    $modularityRoot = if (Test-Path (Join-Path $resolvedWorkspaceRoot "modularity")) {
        Join-Path $resolvedWorkspaceRoot "modularity"
    }
    else {
        $resolvedWorkspaceRoot
    }

    $domainRoot = Join-Path $modularityRoot ("pbi-" + $Domain + "-domain")
    if (-not (Test-Path $domainRoot)) {
        throw "Domain root '$domainRoot' does not exist."
    }

    return $domainRoot
}

function ConvertTo-PbiPromotionCatalogDisplayName {
    param([Parameter(Mandatory = $true)][string]$ModuleId)

    $tokens = @($ModuleId -split "_")
    $displayTokens = foreach ($token in $tokens) {
        if ([string]::IsNullOrWhiteSpace($token)) {
            continue
        }

        $lowerToken = $token.ToLowerInvariant()
        switch ($lowerToken) {
            "mvp" { "MVP"; continue }
            "ui" { "UI"; continue }
            "dax" { "DAX"; continue }
            "pbir" { "PBIR"; continue }
            "pbip" { "PBIP"; continue }
            default {
                $lowerToken.Substring(0, 1).ToUpperInvariant() + $lowerToken.Substring(1)
            }
        }
    }

    return ($displayTokens -join " ")
}

function Register-PbiSemanticPromotionPackageInCatalog {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Domain,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$PackageRoot
    )

    $domainRoot = Resolve-PbiSemanticPromotionDomainRoot -WorkspaceRoot $WorkspaceRoot -Domain $Domain
    $resolvedPackageRoot = [System.IO.Path]::GetFullPath($PackageRoot)
    $resolvedDomainRoot = [System.IO.Path]::GetFullPath($domainRoot)

    if (-not $resolvedPackageRoot.StartsWith($resolvedDomainRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }

    $catalogPath = Join-Path $domainRoot "catalog/modules.json"
    $catalog = if (Test-Path $catalogPath) {
        Read-PbiJsonFile -Path $catalogPath
    }
    else {
        [PSCustomObject]@{
            domain   = $Domain
            packages = @()
        }
    }

    $relativePath = (Get-PbiRelativePath -BasePath $domainRoot -Path $resolvedPackageRoot) -replace "\\", "/"
    $currentEntry = @($catalog.packages | Where-Object { $_.moduleId -eq $Manifest.moduleId } | Select-Object -First 1)
    $compatibility = if ($currentEntry -and $currentEntry.consumerCompatibility) {
        @($currentEntry.consumerCompatibility)
    }
    else {
        @("{0}/generated-by-promotion-v1" -f $Domain)
    }

    $newEntry = [PSCustomObject]@{
        moduleId              = $Manifest.moduleId
        version               = $Manifest.version
        status                = $Manifest.status
        path                  = $relativePath
        displayName           = (ConvertTo-PbiPromotionCatalogDisplayName -ModuleId $Manifest.moduleId)
        consumerCompatibility = @($compatibility)
    }

    $updatedPackages = @()
    $entryReplaced = $false
    foreach ($packageEntry in @($catalog.packages)) {
        if ($packageEntry.moduleId -eq $Manifest.moduleId) {
            $updatedPackages += $newEntry
            $entryReplaced = $true
            continue
        }

        $updatedPackages += $packageEntry
    }

    if (-not $entryReplaced) {
        $updatedPackages += $newEntry
    }

    $catalogObject = [PSCustomObject]@{
        domain   = $Domain
        packages = @($updatedPackages)
    }

    Ensure-PbiDirectory -Path (Split-Path -Parent $catalogPath)
    Write-PbiJsonFile -Path $catalogPath -InputObject $catalogObject

    return [PSCustomObject]@{
        CatalogPath = $catalogPath
        DomainRoot  = $domainRoot
    }
}

function New-PbiSemanticPromotionBaselineRecord {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)][string]$ModuleId
    )

    $tableEntries = New-Object System.Collections.Generic.List[object]
    foreach ($file in (Get-PbiSemanticPromotionTableFiles -Project $Project)) {
        $tableEntries.Add([PSCustomObject]@{
            tableName    = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            relativePath = (Get-PbiRelativePath -BasePath $Project.ProjectRoot -Path $file.FullName)
            sha256       = (Get-PbiFileSha256 -Path $file.FullName)
        })
    }

    $globalEntries = New-Object System.Collections.Generic.List[object]
    foreach ($path in (Get-PbiSemanticPromotionTrackedGlobalFiles -Project $Project)) {
        $globalEntries.Add([PSCustomObject]@{
            relativePath = (Get-PbiRelativePath -BasePath $Project.ProjectRoot -Path $path)
            sha256       = (Get-PbiFileSha256 -Path $path)
        })
    }

    $tableArray = [object[]]$tableEntries.ToArray()
    $globalArray = [object[]]$globalEntries.ToArray()

    return [PSCustomObject]@{
        schemaVersion      = "1.0.0"
        baselineId         = (Get-PbiTimestampKey)
        createdAt          = (Get-PbiUtcTimestamp)
        moduleId           = $ModuleId
        workbenchMode      = "byPath-local-workbench"
        projectId          = $Project.ProjectId
        pbipPath           = (Get-PbiRelativePath -BasePath $Project.ProjectRoot -Path $Project.PbipPath)
        semanticModelPath  = (Get-PbiRelativePath -BasePath $Project.ProjectRoot -Path $Project.SemanticModelPath)
        tables             = $tableArray
        trackedGlobalFiles = $globalArray
    }
}

function Write-PbiSemanticPromotionReportFiles {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [Parameter(Mandatory = $true)]$ReportObject
    )

    $jsonPath = Get-PbiSemanticPromotionReportJsonPath -Project $Project -ModuleId $ModuleId
    $markdownPath = Get-PbiSemanticPromotionReportMarkdownPath -Project $Project -ModuleId $ModuleId

    Ensure-PbiDirectory -Path (Split-Path -Parent $jsonPath)
    Write-PbiJsonFile -Path $jsonPath -InputObject $ReportObject

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(("# Promotion Report - {0}" -f $ModuleId))
    $lines.Add("")
    $lines.Add(('Generated at: `{0}`' -f (Get-PbiUtcTimestamp)))
    $lines.Add("")
    $lines.Add("## Context")
    $lines.Add("")
    $lines.Add(('- Project: `{0}`' -f $Project.ProjectId))
    $lines.Add(('- Baseline Id: `{0}`' -f $ReportObject.baselineId))
    $lines.Add(('- Package root: `{0}`' -f $ReportObject.packageRoot))
    $lines.Add("")
    $lines.Add("## Delta")
    $lines.Add("")
    foreach ($section in @("newTables", "modifiedTables", "removedTables", "blockedFiles")) {
        $values = @($ReportObject.delta.$section)
        $lines.Add(('- {0}: `{1}`' -f $section, ($values -join ", ")))
    }
    $lines.Add("")
    $lines.Add("## External References")
    $lines.Add("")
    foreach ($reference in @($ReportObject.externalReferences)) {
        $lines.Add(('- `{0}` | `{1}` | `{2}` | `{3}`' -f $reference.supportStatus, $reference.referenceType, $reference.referenceText, $reference.location))
    }
    $lines.Add("")
    $lines.Add("## Generated Bindings")
    $lines.Add("")
    foreach ($binding in @($ReportObject.generatedBindings)) {
        $lines.Add(('- `{0}` -> `{1}`' -f $binding.bindingKey, $binding.targetReference))
    }

    Write-PbiUtf8File -Path $markdownPath -Content ($lines -join [Environment]::NewLine)

    return [PSCustomObject]@{
        JsonPath     = $jsonPath
        MarkdownPath = $markdownPath
    }
}

Export-ModuleMember -Function `
    Get-PbiSemanticPromotionSessionRoot, `
    Get-PbiSemanticPromotionBaselinePath, `
    Get-PbiSemanticPromotionReportJsonPath, `
    Get-PbiSemanticPromotionReportMarkdownPath, `
    Get-PbiSemanticPromotionDefinitionRoot, `
    Get-PbiSemanticPromotionTablesRoot, `
    Get-PbiSemanticPromotionProjectTablePath, `
    Get-PbiSemanticPromotionTableFiles, `
    Get-PbiFileSha256, `
    Get-PbiSemanticPromotionTrackedGlobalFiles, `
    Get-PbiTmdlNameFromLine, `
    Get-PbiTmdlTableNameFromFile, `
    Resolve-PbiSemanticPromotionOutputRoot, `
    Resolve-PbiSemanticPromotionDomainRoot, `
    ConvertTo-PbiPromotionCatalogDisplayName, `
    Register-PbiSemanticPromotionPackageInCatalog, `
    New-PbiSemanticPromotionBaselineRecord, `
    Write-PbiSemanticPromotionReportFiles
