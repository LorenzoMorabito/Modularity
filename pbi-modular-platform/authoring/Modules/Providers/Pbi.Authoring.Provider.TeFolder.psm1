Set-StrictMode -Version Latest

function Get-PbiTeFolderDatabasePath {
    param([Parameter(Mandatory = $true)][string]$AuthoringPath)

    return (Join-Path $AuthoringPath "database.json")
}

function Get-PbiTeFolderTablesRoot {
    param([Parameter(Mandatory = $true)][string]$AuthoringPath)

    return (Join-Path $AuthoringPath "tables")
}

function Get-PbiTeFolderCulturesRoot {
    param([Parameter(Mandatory = $true)][string]$AuthoringPath)

    return (Join-Path $AuthoringPath "cultures")
}

function Get-PbiTeFolderTableRoot {
    param(
        [Parameter(Mandatory = $true)][string]$AuthoringPath,
        [Parameter(Mandatory = $true)][string]$TableName
    )

    return (Join-Path (Get-PbiTeFolderTablesRoot -AuthoringPath $AuthoringPath) $TableName)
}

function Get-PbiTeFolderSerializeOptions {
    $options = New-Object Microsoft.AnalysisServices.Tabular.SerializeOptions
    $options.IgnoreChildren = $true
    $options.IgnoreInferredObjects = $true
    $options.IgnoreInferredProperties = $true
    $options.IgnoreTimestamps = $true
    $options.SplitMultilineStrings = $true
    return $options
}

function ConvertFrom-PbiTomJsonText {
    param([Parameter(Mandatory = $true)][string]$JsonText)

    return ($JsonText | ConvertFrom-Json -Depth 100)
}

function Get-PbiTeFolderSerializeAnnotationValue {
    return '{"IgnoreInferredObjects":true,"IgnoreInferredProperties":true,"IgnoreTimestamps":true,"SplitMultilineStrings":true,"PrefixFilenames":false,"LocalTranslations":false,"LocalPerspectives":false,"SortArrays":false,"LocalRelationships":false,"Levels":["Data Sources","Shared Expressions","Perspectives","Relationships","Roles","Tables","Tables/Columns","Tables/Hierarchies","Tables/Measures","Tables/Partitions","Tables/Calculation Items","Translations"]}'
}

function Get-PbiTeFolderTableChildCollections {
    return @(
        [PSCustomObject]@{ PropertyName = "columns"; FolderName = "columns"; CollectionProperty = "Columns" },
        [PSCustomObject]@{ PropertyName = "measures"; FolderName = "measures"; CollectionProperty = "Measures" },
        [PSCustomObject]@{ PropertyName = "hierarchies"; FolderName = "hierarchies"; CollectionProperty = "Hierarchies" },
        [PSCustomObject]@{ PropertyName = "partitions"; FolderName = "partitions"; CollectionProperty = "Partitions" }
    )
}

function Write-PbiTeFolderJsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$JsonText
    )

    $object = ConvertFrom-PbiTomJsonText -JsonText $JsonText
    Write-PbiJsonFile -Path $Path -InputObject $object
}

function Export-PbiModelToTeFolder {
    param(
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Model,
        [Parameter(Mandatory = $true)][string]$AuthoringPath,
        [Parameter(Mandatory = $true)][string[]]$ManagedTables,
        [Parameter(Mandatory = $true)][string[]]$SupportTables
    )

    Ensure-PbiDirectory -Path (Get-PbiTeFolderTablesRoot -AuthoringPath $AuthoringPath)
    Ensure-PbiDirectory -Path (Get-PbiTeFolderCulturesRoot -AuthoringPath $AuthoringPath)

    $allTableNames = @($ManagedTables) + @($SupportTables)
    $databaseObject = [ordered]@{
        name               = $Module.ModuleId
        compatibilityLevel = 1600
        model              = [ordered]@{
            culture                         = if ([string]::IsNullOrWhiteSpace([string]$Model.Culture)) { "en-US" } else { [string]$Model.Culture }
            defaultPowerBIDataSourceVersion = [string]$Model.DefaultPowerBIDataSourceVersion
            sourceQueryCulture              = if ([string]::IsNullOrWhiteSpace([string]$Model.SourceQueryCulture)) { "en-US" } else { [string]$Model.SourceQueryCulture }
            queryGroups                     = @(
                [ordered]@{
                    folder      = "Authoring"
                    annotations = @(
                        [ordered]@{
                            name  = "PBI_QueryGroupOrder"
                            value = "0"
                        }
                    )
                }
            )
            annotations                     = @(
                [ordered]@{
                    name  = "PBI_QueryOrder"
                    value = (ConvertTo-PbiJsonText -InputObject $allTableNames -Compress)
                },
                [ordered]@{
                    name  = "PBI_ProTooling"
                    value = '["DevMode"]'
                },
                [ordered]@{
                    name  = "TabularEditor_SerializeOptions"
                    value = (Get-PbiTeFolderSerializeAnnotationValue)
                }
            )
        }
    }
    Write-PbiJsonFile -Path (Get-PbiTeFolderDatabasePath -AuthoringPath $AuthoringPath) -InputObject $databaseObject

    $serializeOptions = Get-PbiTeFolderSerializeOptions
    foreach ($tableName in @($allTableNames | Sort-Object)) {
        $table = $Model.Tables.Find($tableName)
        if ($null -eq $table) {
            throw "Table '$tableName' was not found in the authoring model."
        }

        $tableRoot = Get-PbiTeFolderTableRoot -AuthoringPath $AuthoringPath -TableName $table.Name
        Ensure-PbiDirectory -Path $tableRoot
        Write-PbiTeFolderJsonFile `
            -Path (Join-Path $tableRoot ($table.Name + ".json")) `
            -JsonText ([Microsoft.AnalysisServices.Tabular.JsonSerializer]::SerializeObject($table, $serializeOptions, 1600))

        foreach ($childDefinition in @(Get-PbiTeFolderTableChildCollections)) {
            $collection = @($table.($childDefinition.CollectionProperty))
            if ($collection.Count -eq 0) {
                continue
            }

            $childRoot = Join-Path $tableRoot $childDefinition.FolderName
            Ensure-PbiDirectory -Path $childRoot
            foreach ($item in @($collection | Sort-Object Name)) {
                Write-PbiTeFolderJsonFile `
                    -Path (Join-Path $childRoot ($item.Name + ".json")) `
                    -JsonText ([Microsoft.AnalysisServices.Tabular.JsonSerializer]::SerializeObject($item, $serializeOptions, 1600))
            }
        }
    }

    $cultures = @($Model.Cultures)
    if ($cultures.Count -eq 0) {
        $cultures = @([PSCustomObject]@{ Name = if ([string]::IsNullOrWhiteSpace([string]$Model.Culture)) { "en-US" } else { [string]$Model.Culture } })
    }

    foreach ($culture in @($cultures | Sort-Object Name)) {
        if ($culture -is [Microsoft.AnalysisServices.Tabular.Culture]) {
            Write-PbiTeFolderJsonFile `
                -Path (Join-Path (Get-PbiTeFolderCulturesRoot -AuthoringPath $AuthoringPath) ($culture.Name + ".json")) `
                -JsonText ([Microsoft.AnalysisServices.Tabular.JsonSerializer]::SerializeObject($culture, $serializeOptions, 1600))
        }
        else {
            Write-PbiJsonFile `
                -Path (Join-Path (Get-PbiTeFolderCulturesRoot -AuthoringPath $AuthoringPath) ($culture.Name + ".json")) `
                -InputObject ([ordered]@{ name = $culture.Name })
        }
    }
}

function Import-PbiTeFolderTableObject {
    param(
        [Parameter(Mandatory = $true)][string]$AuthoringPath,
        [Parameter(Mandatory = $true)][string]$TableName
    )

    $tableRoot = Get-PbiTeFolderTableRoot -AuthoringPath $AuthoringPath -TableName $TableName
    $tableDefinitionPath = Join-Path $tableRoot ($TableName + ".json")
    if (-not (Test-Path $tableDefinitionPath)) {
        throw "Table definition '$tableDefinitionPath' was not found."
    }

    $tableObject = Read-PbiJsonFile -Path $tableDefinitionPath
    foreach ($childDefinition in @(Get-PbiTeFolderTableChildCollections)) {
        $childRoot = Join-Path $tableRoot $childDefinition.FolderName
        $items = @()
        if (Test-Path $childRoot) {
            $items = @(Get-ChildItem -Path $childRoot -Filter "*.json" -File | Sort-Object Name | ForEach-Object {
                    Read-PbiJsonFile -Path $_.FullName
                })
        }

        if ($tableObject.PSObject.Properties.Name -contains $childDefinition.PropertyName) {
            $tableObject.$($childDefinition.PropertyName) = @($items)
        }
        else {
            $tableObject | Add-Member -MemberType NoteProperty -Name $childDefinition.PropertyName -Value @($items)
        }
    }

    return $tableObject
}

function New-PbiTeFolderAuthoringModel {
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

    Initialize-PbiTabularTomAssemblies

    $temporaryTmdlPath = Join-Path ([System.IO.Path]::GetTempPath()) ("pbi-authoring-" + [guid]::NewGuid().ToString() + ".SemanticModel")
    try {
        $temporaryResult = New-PbiTmdlAuthoringModel `
            -WorkspaceRoot $WorkspaceRoot `
            -Module $Module `
            -Summary $Summary `
            -AuthoringPath $temporaryTmdlPath `
            -Force

        $definitionRoot = Join-Path $temporaryResult.AuthoringModelPath "definition"
        $model = [Microsoft.AnalysisServices.Tabular.TmdlSerializer]::DeserializeModelFromFolder($definitionRoot)

        Ensure-PbiDirectory -Path $AuthoringPath
        Export-PbiModelToTeFolder `
            -Module $Module `
            -Model $model `
            -AuthoringPath $AuthoringPath `
            -ManagedTables $Summary.ManagedTables `
            -SupportTables $temporaryResult.SupportTables

        $metadata = New-PbiModuleAuthoringMetadata `
            -WorkspaceRoot $WorkspaceRoot `
            -Module $Module `
            -AuthoringPath $AuthoringPath `
            -AuthoringFormat "te-folder" `
            -ManagedTables $Summary.ManagedTables `
            -SupportTables $temporaryResult.SupportTables
        Write-PbiJsonFile -Path (Get-PbiModuleAuthoringMetadataPath -AuthoringModelPath $AuthoringPath) -InputObject $metadata

        return [PSCustomObject]@{
            Module             = $Module
            AuthoringFormat    = "te-folder"
            AuthoringModelPath = $AuthoringPath
            ManagedTables      = @($Summary.ManagedTables)
            SupportTables      = @($temporaryResult.SupportTables)
            MetadataPath       = (Get-PbiModuleAuthoringMetadataPath -AuthoringModelPath $AuthoringPath)
        }
    }
    finally {
        if (Test-Path $temporaryTmdlPath) {
            Remove-Item -Path $temporaryTmdlPath -Recurse -Force
        }
    }
}

function Sync-PbiPackageFromTeFolderAuthoringModel {
    param(
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Summary,
        [Parameter(Mandatory = $true)][string]$AuthoringPath
    )

    Initialize-PbiTabularTomAssemblies

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
        $tableObject = Import-PbiTeFolderTableObject -AuthoringPath $AuthoringPath -TableName $tableName
        $tableJson = ConvertTo-PbiJsonText -InputObject $tableObject
        $tableTom = [Microsoft.AnalysisServices.Tabular.JsonSerializer]::DeserializeObject([Microsoft.AnalysisServices.Tabular.Table], $tableJson)
        $content = [Microsoft.AnalysisServices.Tabular.TmdlSerializer]::SerializeObject($tableTom, $true)
        $content = Remove-PbiAuthoringNoiseFromTmdlContent -Content $content

        $detectedTableName = Get-PbiTableNameFromTmdlContent -Content $content
        if (-not [string]::Equals($detectedTableName, $tableName, [System.StringComparison]::Ordinal)) {
            throw "Authoring table '$tableName' was serialized as '$detectedTableName'."
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
        AuthoringFormat    = "te-folder"
        AuthoringModelPath = $AuthoringPath
        FilesUpdated       = @($filesUpdated)
        MetadataPath       = $metadataPath
    }
}

Export-ModuleMember -Function New-PbiTeFolderAuthoringModel, Sync-PbiPackageFromTeFolderAuthoringModel
