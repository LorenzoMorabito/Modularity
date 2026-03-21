Set-StrictMode -Version Latest

function Get-PbiModuleDefaultAuthoringModelPath {
    param([Parameter(Mandatory = $true)]$Module)

    return (Join-Path $Module.PackageRoot (Join-Path ".authoring" ($Module.ModuleId + ".SemanticModel")))
}

function Get-PbiModuleAuthoringMetadataPath {
    param([Parameter(Mandatory = $true)][string]$AuthoringModelPath)

    return (Join-Path $AuthoringModelPath ".pbi-modularity-authoring.json")
}

function Get-PbiModuleAuthoringManagedTablePath {
    param(
        [Parameter(Mandatory = $true)][string]$AuthoringModelPath,
        [Parameter(Mandatory = $true)][string]$TableName
    )

    return (Join-Path $AuthoringModelPath ("definition/tables/" + $TableName + ".tmdl"))
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

function New-PbiAuthoringMeasureSupportTableContent {
    param(
        [Parameter(Mandatory = $true)][string]$TableName,
        [Parameter(Mandatory = $true)]$MeasureBindings
    )

    $identifier = Get-PbiTmdlIdentifier -Name $TableName
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(("table {0}" -f $identifier))
    $lines.Add("    isHidden")
    $lines.Add("")

    foreach ($binding in @($MeasureBindings | Sort-Object BindingKey)) {
        $measureIdentifier = Get-PbiTmdlIdentifier -Name ([string]$binding.BindingKey)
        $lines.Add(("    measure {0} = 0" -f $measureIdentifier))
        $lines.Add("        formatString: 0.0;-0.0;0.0")
        $lines.Add("")
    }

    $lines.Add("    column Placeholder")
    $lines.Add("        isHidden")
    $lines.Add("        dataType: string")
    $lines.Add("        summarizeBy: none")
    $lines.Add("        sourceColumn: [Placeholder]")
    $lines.Add("")
    $lines.Add(("    partition {0} = calculated" -f $identifier))
    $lines.Add("        mode: import")
    $lines.Add('        source = DATATABLE("Placeholder", STRING, {{"Authoring"}})')

    return (($lines -join "`r`n") + "`r`n")
}

function New-PbiAuthoringColumnSupportTableContent {
    param([Parameter(Mandatory = $true)]$BindingRecord)

    $bindingInfo = ConvertFrom-PbiColumnBindingKey -BindingKey ([string]$BindingRecord.BindingKey)
    $tableIdentifier = Get-PbiTmdlIdentifier -Name $bindingInfo.TableName
    $columnIdentifier = Get-PbiTmdlIdentifier -Name $bindingInfo.ColumnName
    $stubKind = Get-PbiAuthoringColumnStubKind -BindingRecord $BindingRecord

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(("table {0}" -f $tableIdentifier))
    $lines.Add("    isHidden")
    $lines.Add("")
    $lines.Add(("    column {0}" -f $columnIdentifier))
    $lines.Add("        summarizeBy: none")
    if ($stubKind -eq "date") {
        $lines.Add("        dataType: dateTime")
    }
    else {
        $lines.Add("        dataType: string")
    }
    $lines.Add(("        sourceColumn: [{0}]" -f $bindingInfo.ColumnName))
    $lines.Add("")
    $lines.Add(("    partition {0} = calculated" -f $tableIdentifier))
    $lines.Add("        mode: import")
    if ($stubKind -eq "date") {
        $lines.Add('        source = ```')
        $lines.Add('                SELECTCOLUMNS(')
        $lines.Add('                    CALENDAR(DATE(2024, 1, 1), DATE(2024, 12, 1)),')
        $lines.Add(('                    "{0}", [Date]' -f $bindingInfo.ColumnName))
        $lines.Add('                )')
        $lines.Add('                ```')
    }
    else {
        $lines.Add(('        source = DATATABLE("{0}", STRING, {{"Sample A"},{"Sample B"},{"Sample C"}})' -f $bindingInfo.ColumnName))
    }

    return (($lines -join "`r`n") + "`r`n")
}

function New-PbiAuthoringModelContent {
    param(
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)][string[]]$ManagedTables,
        [string[]]$SupportTables = @()
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("model Model")
    $lines.Add("    culture: en-US")
    $lines.Add("    defaultPowerBIDataSourceVersion: powerBI_V3")
    $lines.Add("    sourceQueryCulture: en-US")
    $lines.Add("")
    $lines.Add("queryGroup Authoring")
    $lines.Add("")
    $lines.Add("    annotation PBI_QueryGroupOrder = 0")
    $lines.Add("")
    $lines.Add(("annotation PBI_QueryOrder = {0}" -f (ConvertTo-PbiJsonText -InputObject (@($ManagedTables) + @($SupportTables)) -Compress)))
    $lines.Add("")
    $lines.Add('annotation PBI_ProTooling = ["DevMode"]')
    $lines.Add("")

    foreach ($tableName in @($ManagedTables + $SupportTables)) {
        $lines.Add(("ref table {0}" -f (Get-PbiTmdlIdentifier -Name $tableName)))
    }

    $lines.Add("")
    $lines.Add("ref cultureInfo en-US")

    return (($lines -join "`r`n") + "`r`n")
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

function New-PbiModuleAuthoringModel {
    param(
        [string]$WorkspaceRoot,
        [string]$Domain,
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [string]$AuthoringPath,
        [switch]$Force
    )

    $resolvedWorkspaceRoot = Get-PbiInstallerWorkspaceRoot -WorkspaceRoot $WorkspaceRoot -ScriptRoot $PSScriptRoot
    $module = Get-PbiSingleModule -WorkspaceRoot $resolvedWorkspaceRoot -Domain $Domain -ModuleId $ModuleId
    $summary = Get-PbiModuleAuthoringManifestSummary -Module $module
    $resolvedAuthoringPath = if ($AuthoringPath) { [System.IO.Path]::GetFullPath($AuthoringPath) } else { Get-PbiModuleDefaultAuthoringModelPath -Module $module }

    if ((Test-Path $resolvedAuthoringPath) -and (-not $Force)) {
        throw "Authoring model path '$resolvedAuthoringPath' already exists. Use -Force to overwrite."
    }

    if (Test-Path $resolvedAuthoringPath) {
        Remove-Item -Path $resolvedAuthoringPath -Recurse -Force
    }

    $definitionRoot = Join-Path $resolvedAuthoringPath "definition"
    $tablesRoot = Join-Path $definitionRoot "tables"
    $culturesRoot = Join-Path $definitionRoot "cultures"
    Ensure-PbiDirectory -Path $tablesRoot
    Ensure-PbiDirectory -Path $culturesRoot

    foreach ($tableName in @($summary.ManagedTables)) {
        $sourcePath = Join-Path $module.PackageRoot ("semantic/" + $tableName + ".tmdl")
        if (-not (Test-Path $sourcePath)) {
            throw "Managed semantic table '$tableName' was not found in package '$($module.PackageRoot)'."
        }

        $destinationPath = Get-PbiModuleAuthoringManagedTablePath -AuthoringModelPath $resolvedAuthoringPath -TableName $tableName
        Write-PbiUtf8File -Path $destinationPath -Content (Get-Content -Path $sourcePath -Raw)
    }

    $supportTableNames = New-Object System.Collections.Generic.List[string]
    $measureSupportTableName = "_MOD Authoring Bindings"
    if (@($summary.MeasureBindings).Count -gt 0) {
        if (@($summary.ManagedTables) -contains $measureSupportTableName) {
            throw "Module '$($module.ModuleId)' already declares a semantic table named '$measureSupportTableName'."
        }

        Write-PbiUtf8File `
            -Path (Get-PbiModuleAuthoringManagedTablePath -AuthoringModelPath $resolvedAuthoringPath -TableName $measureSupportTableName) `
            -Content (New-PbiAuthoringMeasureSupportTableContent -TableName $measureSupportTableName -MeasureBindings $summary.MeasureBindings)
        $supportTableNames.Add($measureSupportTableName)
    }

    foreach ($binding in @($summary.ColumnBindings)) {
        $bindingInfo = ConvertFrom-PbiColumnBindingKey -BindingKey ([string]$binding.BindingKey)
        if (@($summary.ManagedTables) -contains $bindingInfo.TableName) {
            throw "Column binding support table '$($bindingInfo.TableName)' collides with a managed table in module '$($module.ModuleId)'."
        }

        if ($supportTableNames -contains $bindingInfo.TableName) {
            continue
        }

        Write-PbiUtf8File `
            -Path (Get-PbiModuleAuthoringManagedTablePath -AuthoringModelPath $resolvedAuthoringPath -TableName $bindingInfo.TableName) `
            -Content (New-PbiAuthoringColumnSupportTableContent -BindingRecord $binding)
        $supportTableNames.Add($bindingInfo.TableName)
    }

    Write-PbiUtf8File -Path (Join-Path $resolvedAuthoringPath ".platform") -Content (ConvertTo-PbiJsonText -InputObject ([ordered]@{
            '$schema' = "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json"
            metadata  = [ordered]@{
                type        = "SemanticModel"
                displayName = ($module.DisplayName + " Authoring")
            }
            config    = [ordered]@{
                version   = "2.0"
                logicalId = ([guid]::NewGuid().ToString())
            }
        }))

    Write-PbiUtf8File -Path (Join-Path $resolvedAuthoringPath "definition.pbism") -Content (ConvertTo-PbiJsonText -InputObject ([ordered]@{
            '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/semanticModel/definitionProperties/1.0.0/schema.json"
            version   = "4.2"
            settings  = [ordered]@{}
        }))

    Write-PbiUtf8File -Path (Join-Path $definitionRoot "database.tmdl") -Content ("database`r`n`tcompatibilityLevel: 1600`r`n")
    Write-PbiUtf8File -Path (Join-Path $definitionRoot "model.tmdl") -Content (New-PbiAuthoringModelContent -Module $module -ManagedTables $summary.ManagedTables -SupportTables @($supportTableNames))
    Write-PbiUtf8File -Path (Join-Path $culturesRoot "en-US.tmdl") -Content ("cultureInfo en-US`r`n")
    Write-PbiJsonFile -Path (Join-Path $resolvedAuthoringPath "diagramLayout.json") -InputObject ([ordered]@{})

    $metadata = [ordered]@{
        schemaVersion           = "1.0.0"
        moduleId                = $module.ModuleId
        domain                  = $module.Domain
        moduleVersion           = $module.Version
        generatedAt             = Get-PbiUtcTimestamp
        packageRoot             = $module.PackageRoot
        packageRootRelativePath = Get-PbiRelativePath -BasePath $resolvedWorkspaceRoot -Path $module.PackageRoot
        authoringModelPath      = $resolvedAuthoringPath
        managedSemanticTables   = @($summary.ManagedTables)
        supportTables           = @($supportTableNames)
    }
    Write-PbiJsonFile -Path (Get-PbiModuleAuthoringMetadataPath -AuthoringModelPath $resolvedAuthoringPath) -InputObject $metadata

    return [PSCustomObject]@{
        Module             = $module
        AuthoringModelPath = $resolvedAuthoringPath
        ManagedTables      = @($summary.ManagedTables)
        SupportTables      = @($supportTableNames)
        MetadataPath       = (Get-PbiModuleAuthoringMetadataPath -AuthoringModelPath $resolvedAuthoringPath)
    }
}

function Sync-PbiModulePackageFromAuthoringModel {
    param(
        [string]$WorkspaceRoot,
        [string]$Domain,
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [string]$AuthoringPath
    )

    $resolvedWorkspaceRoot = Get-PbiInstallerWorkspaceRoot -WorkspaceRoot $WorkspaceRoot -ScriptRoot $PSScriptRoot
    $module = Get-PbiSingleModule -WorkspaceRoot $resolvedWorkspaceRoot -Domain $Domain -ModuleId $ModuleId
    $summary = Get-PbiModuleAuthoringManifestSummary -Module $module
    $resolvedAuthoringPath = if ($AuthoringPath) { [System.IO.Path]::GetFullPath($AuthoringPath) } else { Get-PbiModuleDefaultAuthoringModelPath -Module $module }
    $metadataPath = Get-PbiModuleAuthoringMetadataPath -AuthoringModelPath $resolvedAuthoringPath

    if (-not (Test-Path $metadataPath)) {
        throw "Authoring metadata file '$metadataPath' was not found. Generate the sandbox first with new-authoring-model."
    }

    $metadata = Read-PbiJsonFile -Path $metadataPath
    if (-not [string]::Equals([string]$metadata.moduleId, $module.ModuleId, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Authoring model '$resolvedAuthoringPath' belongs to module '$($metadata.moduleId)', not '$($module.ModuleId)'."
    }

    $metadataManagedTables = @($metadata.managedSemanticTables)
    if ((@($summary.ManagedTables | Sort-Object) -join "|") -ne (@($metadataManagedTables | Sort-Object) -join "|")) {
        throw "Authoring metadata is out of sync with the current manifest. Regenerate the authoring model before syncing."
    }

    $filesUpdated = New-Object System.Collections.Generic.List[string]
    foreach ($tableName in @($summary.ManagedTables)) {
        $sourcePath = Get-PbiModuleAuthoringManagedTablePath -AuthoringModelPath $resolvedAuthoringPath -TableName $tableName
        if (-not (Test-Path $sourcePath)) {
            throw "Managed table '$tableName' is missing from authoring model '$resolvedAuthoringPath'."
        }

        $content = Get-Content -Path $sourcePath -Raw
        $detectedTableName = Get-PbiTableNameFromTmdlContent -Content $content
        if (-not [string]::Equals($detectedTableName, $tableName, [System.StringComparison]::Ordinal)) {
            throw "Authoring table file '$sourcePath' declares table '$detectedTableName' but module manifest expects '$tableName'."
        }

        $destinationPath = Join-Path $module.PackageRoot ("semantic/" + $tableName + ".tmdl")
        $existingContent = if (Test-Path $destinationPath) { Get-Content -Path $destinationPath -Raw } else { "" }
        if (-not [string]::Equals($existingContent, $content, [System.StringComparison]::Ordinal)) {
            Write-PbiUtf8File -Path $destinationPath -Content $content
            $filesUpdated.Add($destinationPath)
        }
    }

    return [PSCustomObject]@{
        Module             = $module
        AuthoringModelPath = $resolvedAuthoringPath
        FilesUpdated       = @($filesUpdated)
        MetadataPath       = $metadataPath
    }
}

Export-ModuleMember -Function Get-PbiModuleDefaultAuthoringModelPath, Get-PbiModuleAuthoringMetadataPath, New-PbiModuleAuthoringModel, Sync-PbiModulePackageFromAuthoringModel
