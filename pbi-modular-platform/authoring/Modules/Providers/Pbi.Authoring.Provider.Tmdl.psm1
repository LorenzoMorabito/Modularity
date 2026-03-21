Set-StrictMode -Version Latest

function Get-PbiTmdlAuthoringManagedTablePath {
    param(
        [Parameter(Mandatory = $true)][string]$AuthoringModelPath,
        [Parameter(Mandatory = $true)][string]$TableName
    )

    return (Join-Path $AuthoringModelPath ("definition/tables/" + $TableName + ".tmdl"))
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

function New-PbiTmdlAuthoringModel {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Summary,
        [Parameter(Mandatory = $true)][string]$AuthoringPath,
        [switch]$Force
    )

    if ((Test-Path $AuthoringPath) -and (-not $Force)) {
        throw "Authoring model path '$AuthoringPath' already exists. Use -Force to overwrite."
    }

    if (Test-Path $AuthoringPath) {
        Remove-Item -Path $AuthoringPath -Recurse -Force
    }

    $definitionRoot = Join-Path $AuthoringPath "definition"
    $tablesRoot = Join-Path $definitionRoot "tables"
    $culturesRoot = Join-Path $definitionRoot "cultures"
    Ensure-PbiDirectory -Path $tablesRoot
    Ensure-PbiDirectory -Path $culturesRoot

    foreach ($tableName in @($Summary.ManagedTables)) {
        $sourcePath = Join-Path $Module.PackageRoot ("semantic/" + $tableName + ".tmdl")
        if (-not (Test-Path $sourcePath)) {
            throw "Managed semantic table '$tableName' was not found in package '$($Module.PackageRoot)'."
        }

        $destinationPath = Get-PbiTmdlAuthoringManagedTablePath -AuthoringModelPath $AuthoringPath -TableName $tableName
        Write-PbiUtf8File -Path $destinationPath -Content (Get-Content -Path $sourcePath -Raw)
    }

    $supportTableNames = New-Object System.Collections.Generic.List[string]
    $measureSupportTableName = "_MOD Authoring Bindings"
    if (@($Summary.MeasureBindings).Count -gt 0) {
        if (@($Summary.ManagedTables) -contains $measureSupportTableName) {
            throw "Module '$($Module.ModuleId)' already declares a semantic table named '$measureSupportTableName'."
        }

        Write-PbiUtf8File `
            -Path (Get-PbiTmdlAuthoringManagedTablePath -AuthoringModelPath $AuthoringPath -TableName $measureSupportTableName) `
            -Content (New-PbiAuthoringMeasureSupportTableContent -TableName $measureSupportTableName -MeasureBindings $Summary.MeasureBindings)
        $supportTableNames.Add($measureSupportTableName)
    }

    foreach ($binding in @($Summary.ColumnBindings)) {
        $bindingInfo = ConvertFrom-PbiColumnBindingKey -BindingKey ([string]$binding.BindingKey)
        if (@($Summary.ManagedTables) -contains $bindingInfo.TableName) {
            throw "Column binding support table '$($bindingInfo.TableName)' collides with a managed table in module '$($Module.ModuleId)'."
        }

        if ($supportTableNames -contains $bindingInfo.TableName) {
            continue
        }

        Write-PbiUtf8File `
            -Path (Get-PbiTmdlAuthoringManagedTablePath -AuthoringModelPath $AuthoringPath -TableName $bindingInfo.TableName) `
            -Content (New-PbiAuthoringColumnSupportTableContent -BindingRecord $binding)
        $supportTableNames.Add($bindingInfo.TableName)
    }

    Write-PbiUtf8File -Path (Join-Path $AuthoringPath ".platform") -Content (ConvertTo-PbiJsonText -InputObject ([ordered]@{
            '$schema' = "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json"
            metadata  = [ordered]@{
                type        = "SemanticModel"
                displayName = ($Module.DisplayName + " Authoring")
            }
            config    = [ordered]@{
                version   = "2.0"
                logicalId = ([guid]::NewGuid().ToString())
            }
        }))

    Write-PbiUtf8File -Path (Join-Path $AuthoringPath "definition.pbism") -Content (ConvertTo-PbiJsonText -InputObject ([ordered]@{
            '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/semanticModel/definitionProperties/1.0.0/schema.json"
            version   = "4.2"
            settings  = [ordered]@{}
        }))

    Write-PbiUtf8File -Path (Join-Path $definitionRoot "database.tmdl") -Content ("database`r`n`tcompatibilityLevel: 1600`r`n")
    Write-PbiUtf8File -Path (Join-Path $definitionRoot "model.tmdl") -Content (New-PbiAuthoringModelContent -Module $Module -ManagedTables $Summary.ManagedTables -SupportTables @($supportTableNames))
    Write-PbiUtf8File -Path (Join-Path $culturesRoot "en-US.tmdl") -Content ("cultureInfo en-US`r`n")
    Write-PbiJsonFile -Path (Join-Path $AuthoringPath "diagramLayout.json") -InputObject ([ordered]@{})

    $metadata = New-PbiModuleAuthoringMetadata `
        -WorkspaceRoot $WorkspaceRoot `
        -Module $Module `
        -AuthoringPath $AuthoringPath `
        -AuthoringFormat "tmdl" `
        -ManagedTables $Summary.ManagedTables `
        -SupportTables @($supportTableNames)
    Write-PbiJsonFile -Path (Get-PbiModuleAuthoringMetadataPath -AuthoringModelPath $AuthoringPath) -InputObject $metadata

    return [PSCustomObject]@{
        Module             = $Module
        AuthoringFormat    = "tmdl"
        AuthoringModelPath = $AuthoringPath
        ManagedTables      = @($Summary.ManagedTables)
        SupportTables      = @($supportTableNames)
        MetadataPath       = (Get-PbiModuleAuthoringMetadataPath -AuthoringModelPath $AuthoringPath)
    }
}

function Sync-PbiPackageFromTmdlAuthoringModel {
    param(
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Summary,
        [Parameter(Mandatory = $true)][string]$AuthoringPath
    )

    $metadataPath = Get-PbiModuleAuthoringMetadataPath -AuthoringModelPath $AuthoringPath
    if (-not (Test-Path $metadataPath)) {
        throw "Authoring metadata file '$metadataPath' was not found. Generate the sandbox first with new-authoring-model."
    }

    $metadata = Read-PbiJsonFile -Path $metadataPath
    if (-not [string]::Equals([string]$metadata.moduleId, $Module.ModuleId, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Authoring model '$AuthoringPath' belongs to module '$($metadata.moduleId)', not '$($Module.ModuleId)'."
    }

    $metadataManagedTables = @($metadata.managedSemanticTables)
    if ((@($Summary.ManagedTables | Sort-Object) -join "|") -ne (@($metadataManagedTables | Sort-Object) -join "|")) {
        throw "Authoring metadata is out of sync with the current manifest. Regenerate the authoring model before syncing."
    }

    $filesUpdated = New-Object System.Collections.Generic.List[string]
    foreach ($tableName in @($Summary.ManagedTables)) {
        $sourcePath = Get-PbiTmdlAuthoringManagedTablePath -AuthoringModelPath $AuthoringPath -TableName $tableName
        if (-not (Test-Path $sourcePath)) {
            throw "Managed table '$tableName' is missing from authoring model '$AuthoringPath'."
        }

        $content = Get-Content -Path $sourcePath -Raw
        $detectedTableName = Get-PbiTableNameFromTmdlContent -Content $content
        if (-not [string]::Equals($detectedTableName, $tableName, [System.StringComparison]::Ordinal)) {
            throw "Authoring table file '$sourcePath' declares table '$detectedTableName' but module manifest expects '$tableName'."
        }

        $destinationPath = Join-Path $Module.PackageRoot ("semantic/" + $tableName + ".tmdl")
        $existingContent = if (Test-Path $destinationPath) { Get-Content -Path $destinationPath -Raw } else { "" }
        if (-not [string]::Equals($existingContent, $content, [System.StringComparison]::Ordinal)) {
            Write-PbiUtf8File -Path $destinationPath -Content $content
            $filesUpdated.Add($destinationPath)
        }
    }

    return [PSCustomObject]@{
        Module             = $Module
        AuthoringFormat    = "tmdl"
        AuthoringModelPath = $AuthoringPath
        FilesUpdated       = @($filesUpdated)
        MetadataPath       = $metadataPath
    }
}

Export-ModuleMember -Function Get-PbiTmdlAuthoringManagedTablePath, New-PbiTmdlAuthoringModel, Sync-PbiPackageFromTmdlAuthoringModel
