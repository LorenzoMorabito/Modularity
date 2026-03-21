Set-StrictMode -Version Latest

function Get-PbiModuleDefaultAuthoringRoot {
    param([Parameter(Mandatory = $true)]$Module)

    return (Join-Path $Module.PackageRoot ".authoring")
}

function Get-PbiModuleDefaultAuthoringPath {
    param(
        [Parameter(Mandatory = $true)]$Module,
        [ValidateSet("te-folder", "tmdl")]
        [string]$AuthoringFormat = "te-folder"
    )

    $authoringRoot = Get-PbiModuleDefaultAuthoringRoot -Module $Module
    switch ($AuthoringFormat) {
        "tmdl" {
            return (Join-Path $authoringRoot ($Module.ModuleId + ".SemanticModel"))
        }
        "te-folder" {
            return (Join-Path $authoringRoot $Module.ModuleId)
        }
    }
}

function Get-PbiModuleDefaultAuthoringModelPath {
    param([Parameter(Mandatory = $true)]$Module)

    return (Get-PbiModuleDefaultAuthoringPath -Module $Module -AuthoringFormat "tmdl")
}

function Get-PbiModuleAuthoringMetadataPath {
    param([Parameter(Mandatory = $true)][string]$AuthoringModelPath)

    return (Join-Path $AuthoringModelPath ".pbi-modularity-authoring.json")
}

function Get-PbiObjectArrayProperty {
    param(
        [Parameter(Mandatory = $true)]$InputObject,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if (($null -eq $InputObject) -or (-not ($InputObject.PSObject.Properties.Name -contains $Name))) {
        return @()
    }

    return @($InputObject.$Name)
}

function Get-PbiModuleAuthoringBindingRecords {
    param([Parameter(Mandatory = $true)]$Manifest)

    $records = @()
    $knownKeys = @{}
    $contractRoles = @()

    if (
        ($Manifest.PSObject.Properties.Name -contains "bindingContract") -and
        ($null -ne $Manifest.bindingContract) -and
        ($Manifest.bindingContract.PSObject.Properties.Name -contains "roles") -and
        ($null -ne $Manifest.bindingContract.roles)
    ) {
        $contractRoles = @($Manifest.bindingContract.roles)
    }

    foreach ($role in $contractRoles) {
        $bindingKey = [string]$role.bindingKey
        $kind = [string]$role.kind
        if ([string]::IsNullOrWhiteSpace($bindingKey) -or [string]::IsNullOrWhiteSpace($kind)) {
            continue
        }

        if (-not $knownKeys.ContainsKey($bindingKey)) {
            $knownKeys[$bindingKey] = $true
            $records += [PSCustomObject]@{
                Kind         = $kind
                BindingKey   = $bindingKey
                Label        = [string]$role.label
                Description  = [string]$role.description
                SemanticRole = [string]$role.semanticRole
            }
        }
    }

    foreach ($bindingKey in @(Get-PbiObjectArrayProperty -InputObject $Manifest.requires -Name "coreMeasures")) {
        $resolvedKey = [string]$bindingKey
        if ((-not [string]::IsNullOrWhiteSpace($resolvedKey)) -and (-not $knownKeys.ContainsKey($resolvedKey))) {
            $knownKeys[$resolvedKey] = $true
            $records += [PSCustomObject]@{
                Kind         = "measure"
                BindingKey   = $resolvedKey
                Label        = $resolvedKey
                Description  = ""
                SemanticRole = ""
            }
        }
    }

    foreach ($bindingKey in @(Get-PbiObjectArrayProperty -InputObject $Manifest.requires -Name "coreColumns")) {
        $resolvedKey = [string]$bindingKey
        if ((-not [string]::IsNullOrWhiteSpace($resolvedKey)) -and (-not $knownKeys.ContainsKey($resolvedKey))) {
            $knownKeys[$resolvedKey] = $true
            $records += [PSCustomObject]@{
                Kind         = "column"
                BindingKey   = $resolvedKey
                Label        = $resolvedKey
                Description  = ""
                SemanticRole = ""
            }
        }
    }

    return @($records)
}

function ConvertFrom-PbiColumnBindingKey {
    param([Parameter(Mandatory = $true)][string]$BindingKey)

    if ($BindingKey -notmatch "^(?<Table>.+?)\[(?<Column>.+)\]$") {
        throw "Column binding key '$BindingKey' is not in the expected Table[Column] format."
    }

    return [PSCustomObject]@{
        TableName  = [string]$Matches.Table
        ColumnName = [string]$Matches.Column
    }
}

function Get-PbiAuthoringColumnStubKind {
    param([Parameter(Mandatory = $true)]$BindingRecord)

    $semanticRole = [string]$BindingRecord.SemanticRole
    $bindingKey = [string]$BindingRecord.BindingKey
    $label = [string]$BindingRecord.Label

    if (
        ($semanticRole -match "(?i)calendar|period|date|time") -or
        ($bindingKey -match "(?i)period|date|time") -or
        ($label -match "(?i)period|date|time")
    ) {
        return "date"
    }

    return "text"
}

function Get-PbiTableNameFromTmdlContent {
    param([Parameter(Mandatory = $true)][string]$Content)

    $match = [regex]::Match($Content, "(?m)^\s*table\s+(?:'((?:[^']|'')+)'|([A-Za-z_][A-Za-z0-9_]*))(?=\s*$|\s)")
    if (-not $match.Success) {
        throw "Unable to detect table name from TMDL content."
    }

    if ($match.Groups[1].Success) {
        return $match.Groups[1].Value.Replace("''", "'")
    }

    return $match.Groups[2].Value
}

function Get-PbiModuleAuthoringManifestSummary {
    param([Parameter(Mandatory = $true)]$Module)

    $manifest = $Module.Manifest
    if ([string]::Equals([string]$manifest.type, "report-only", [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Authoring sandbox is currently supported only for semantic modules."
    }

    $managedTables = @(Get-PbiObjectArrayProperty -InputObject $manifest.provides -Name "semanticTables")
    if ($managedTables.Count -eq 0) {
        throw "Module '$($Module.ModuleId)' does not declare semantic tables."
    }

    $bindingRecords = @(Get-PbiModuleAuthoringBindingRecords -Manifest $manifest)
    $measureBindings = @($bindingRecords | Where-Object { $_.Kind -eq "measure" })
    $columnBindings = @($bindingRecords | Where-Object { $_.Kind -eq "column" })

    return [PSCustomObject]@{
        ManagedTables   = @($managedTables)
        BindingRecords  = @($bindingRecords)
        MeasureBindings = @($measureBindings)
        ColumnBindings  = @($columnBindings)
    }
}

function New-PbiModuleAuthoringMetadata {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)][string]$AuthoringPath,
        [Parameter(Mandatory = $true)][string]$AuthoringFormat,
        [Parameter(Mandatory = $true)][string[]]$ManagedTables,
        [string[]]$SupportTables = @()
    )

    return [ordered]@{
        schemaVersion           = "1.1.0"
        authoringFormat         = $AuthoringFormat
        moduleId                = $Module.ModuleId
        domain                  = $Module.Domain
        moduleVersion           = $Module.Version
        generatedAt             = Get-PbiUtcTimestamp
        packageRoot             = $Module.PackageRoot
        packageRootRelativePath = Get-PbiRelativePath -BasePath $WorkspaceRoot -Path $Module.PackageRoot
        authoringModelPath      = $AuthoringPath
        managedSemanticTables   = @($ManagedTables)
        supportTables           = @($SupportTables)
    }
}

function Resolve-PbiModuleAuthoringFormatFromPath {
    param([Parameter(Mandatory = $true)][string]$AuthoringPath)

    $metadataPath = Get-PbiModuleAuthoringMetadataPath -AuthoringModelPath $AuthoringPath
    if (Test-Path $metadataPath) {
        $metadata = Read-PbiJsonFile -Path $metadataPath
        if (
            ($metadata.PSObject.Properties.Name -contains "authoringFormat") -and
            (-not [string]::IsNullOrWhiteSpace([string]$metadata.authoringFormat))
        ) {
            return [string]$metadata.authoringFormat
        }
    }

    if ([string]::Equals([System.IO.Path]::GetExtension($AuthoringPath), ".SemanticModel", [System.StringComparison]::OrdinalIgnoreCase)) {
        return "tmdl"
    }

    return "te-folder"
}

function Initialize-PbiTabularTomAssemblies {
    $assemblyNames = @(
        "Microsoft.AnalysisServices.Core.dll",
        "Microsoft.AnalysisServices.Tabular.dll"
    )
    $candidateRoots = @(
        "C:\Program Files\Tabular Editor 3",
        "C:\Program Files (x86)\Tabular Editor",
        "C:\Program Files\Microsoft Power BI Desktop\bin"
    )

    foreach ($assemblyName in $assemblyNames) {
        $alreadyLoaded = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
            $_.GetName().Name -eq ([System.IO.Path]::GetFileNameWithoutExtension($assemblyName))
        }
        if ($alreadyLoaded) {
            continue
        }

        $loaded = $false
        foreach ($candidateRoot in $candidateRoots) {
            $candidatePath = Join-Path $candidateRoot $assemblyName
            if (-not (Test-Path $candidatePath)) {
                continue
            }

            Add-Type -Path $candidatePath
            $loaded = $true
            break
        }

        if (-not $loaded) {
            throw "Required TOM assembly '$assemblyName' was not found. Install Tabular Editor 3 or provide the Microsoft.AnalysisServices assemblies locally."
        }
    }
}

function Remove-PbiAuthoringNoiseFromTmdlContent {
    param([Parameter(Mandatory = $true)][string]$Content)

    $normalized = $Content -replace "`r?`n", "`n"
    $normalized = $normalized -replace "(?m)^[ \t]*lineageTag:.*\n", ""
    $normalized = $normalized -replace "(?m)^[ \t]*annotation PBI_Id =.*\n", ""
    $normalized = $normalized -replace "(?m)^[ \t]*annotation SummarizationSetBy = Automatic\n", ""
    $normalized = $normalized -replace "(?m)^[ \t]*isNameInferred\n", ""
    $normalized = $normalized -replace "(?m)(\n){3,}", "`n`n"
    $normalized = $normalized.TrimEnd("`n")

    return ($normalized -replace "`n", "`r`n") + "`r`n"
}

Export-ModuleMember -Function `
    Get-PbiModuleDefaultAuthoringRoot, `
    Get-PbiModuleDefaultAuthoringPath, `
    Get-PbiModuleDefaultAuthoringModelPath, `
    Get-PbiModuleAuthoringMetadataPath, `
    Get-PbiObjectArrayProperty, `
    Get-PbiModuleAuthoringBindingRecords, `
    ConvertFrom-PbiColumnBindingKey, `
    Get-PbiAuthoringColumnStubKind, `
    Get-PbiTableNameFromTmdlContent, `
    Get-PbiModuleAuthoringManifestSummary, `
    New-PbiModuleAuthoringMetadata, `
    Resolve-PbiModuleAuthoringFormatFromPath, `
    Initialize-PbiTabularTomAssemblies, `
    Remove-PbiAuthoringNoiseFromTmdlContent
