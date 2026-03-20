Set-StrictMode -Version Latest

function Get-PbiModuleRenderingStrategy {
    param([Parameter(Mandatory = $true)]$Manifest)

    if (($Manifest.PSObject.Properties.Name -contains "rendering") -and $Manifest.rendering -and $Manifest.rendering.strategy) {
        return [string]$Manifest.rendering.strategy
    }

    return "static"
}

function New-PbiRenderedModuleFileMapping {
    param(
        [string]$TableName,
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$RelativePath,
        [string]$SourceContent
    )

    return [PSCustomObject]@{
        TableName        = $TableName
        SourcePath       = $SourcePath
        DestinationPath  = $DestinationPath
        RelativePath     = $RelativePath
        SourceContent    = $SourceContent
    }
}

function Get-PbiFlexBindingItems {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$ResolvedMappings,
        [Parameter(Mandatory = $true)][string]$CollectionId
    )

    $selections = Get-PbiModuleBindingSelections -Manifest $Manifest -ResolvedMappings $ResolvedMappings
    if ($selections.Contains($CollectionId)) {
        return @($selections[$CollectionId] | Sort-Object ordinal)
    }

    return @()
}

function Get-PbiFlexVisibleCount {
    param(
        [Parameter(Mandatory = $true)][int]$ItemCount,
        [Parameter(Mandatory = $true)][int]$PreferredCount
    )

    if ($ItemCount -le 0) {
        return 0
    }

    return [Math]::Min($ItemCount, [Math]::Max(1, $PreferredCount))
}

function Get-PbiFlexDimensionBindingTableName {
    param([Parameter(Mandatory = $true)]$Item)

    return (ConvertFrom-PbiColumnReference -ColumnReference $Item.bindingKey).TableName
}

function Get-PbiBindingTokenLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Label", "Value", "Table", "Column", "QueryRef")]
        [string]$Property,
        [Parameter(Mandatory = $true)][string]$BindingKey
    )

    return ("{{{{binding{0}:{1}}}}}" -f $Property, $BindingKey)
}

function New-PbiFlexFlatInputsTemplate {
    param([Parameter(Mandatory = $true)]$MeasureItems)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table 'MOD Flex Flat'")
    $lines.Add("")

    for ($index = 0; $index -lt $MeasureItems.Count; $index++) {
        $item = $MeasureItems[$index]
        $measureOrdinal = $index + 1
        $lines.Add(("`tmeasure 'Flat Input Metric {0}' = [{1}]" -f $measureOrdinal, $item.bindingKey))
        $lines.Add("`t`tdisplayFolder: Selected Metrics")
        $lines.Add("")
    }

    $lines.Add("`tcolumn Column")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [Column]")
    $lines.Add("")
    $lines.Add("`tpartition 'MOD Flex Flat' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource = Row(""Column"", BLANK())")

    return ($lines -join "`r`n")
}

function New-PbiFlexFlatDimensionsTemplate {
    param([Parameter(Mandatory = $true)]$DimensionItems)

    $rows = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $DimensionItems.Count; $index++) {
        $item = $DimensionItems[$index]
        $bindingTable = Get-PbiFlexDimensionBindingTableName -Item $item
        $rows.Add(('                ("{0}", NAMEOF(''{1}''[Value]), {2})' -f (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$item.bindingKey)), $bindingTable, $index))
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD Flex Flat Dimensions'")
    $lines.Add("    isHidden")
    $lines.Add("")
    $lines.Add("    column 'Flat Dimension'")
    $lines.Add("        summarizeBy: none")
    $lines.Add("        sourceColumn: [Value1]")
    $lines.Add("        sortByColumn: 'Flat Dimension Order'")
    $lines.Add("")
    $lines.Add("        relatedColumnDetails")
    $lines.Add("            groupByColumn: 'Flat Dimension Fields'")
    $lines.Add("")
    $lines.Add("    column 'Flat Dimension Fields'")
    $lines.Add("        isHidden")
    $lines.Add("        summarizeBy: none")
    $lines.Add("        sourceColumn: [Value2]")
    $lines.Add("        sortByColumn: 'Flat Dimension Order'")
    $lines.Add("")
    $lines.Add("        extendedProperty ParameterMetadata =")
    $lines.Add("                {")
    $lines.Add('                  "version": 3,')
    $lines.Add('                  "kind": 2')
    $lines.Add("                }")
    $lines.Add("")
    $lines.Add("    column 'Flat Dimension Order'")
    $lines.Add("        isHidden")
    $lines.Add("        formatString: 0")
    $lines.Add("        summarizeBy: none")
    $lines.Add("        sourceColumn: [Value3]")
    $lines.Add("")
    $lines.Add("    partition '_MOD Flex Flat Dimensions' = calculated")
    $lines.Add("        mode: import")
    $lines.Add("        source =")
    $lines.Add("                {")
    $lines.Add(($rows -join ",`r`n"))
    $lines.Add("                }")

    return (($lines -join "`r`n") + "`r`n")
}

function New-PbiFlexFlatMeasuresTemplate {
    param([Parameter(Mandatory = $true)]$MeasureItems)

    $rows = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $MeasureItems.Count; $index++) {
        $item = $MeasureItems[$index]
        $measureOrdinal = $index + 1
        $rows.Add(('                ("{0}", NAMEOF(''MOD Flex Flat''[Flat Input Metric {1}]), {2})' -f (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$item.bindingKey)), $measureOrdinal, $index))
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD Flex Flat Measures'")
    $lines.Add("    isHidden")
    $lines.Add("")
    $lines.Add("    column 'Flat Measure'")
    $lines.Add("        summarizeBy: none")
    $lines.Add("        sourceColumn: [Value1]")
    $lines.Add("        sortByColumn: 'Flat Measure Order'")
    $lines.Add("")
    $lines.Add("        relatedColumnDetails")
    $lines.Add("            groupByColumn: 'Flat Measure Fields'")
    $lines.Add("")
    $lines.Add("    column 'Flat Measure Fields'")
    $lines.Add("        isHidden")
    $lines.Add("        summarizeBy: none")
    $lines.Add("        sourceColumn: [Value2]")
    $lines.Add("        sortByColumn: 'Flat Measure Order'")
    $lines.Add("")
    $lines.Add("        extendedProperty ParameterMetadata =")
    $lines.Add("                {")
    $lines.Add('                  "version": 3,')
    $lines.Add('                  "kind": 2')
    $lines.Add("                }")
    $lines.Add("")
    $lines.Add("    column 'Flat Measure Order'")
    $lines.Add("        isHidden")
    $lines.Add("        formatString: 0")
    $lines.Add("        summarizeBy: none")
    $lines.Add("        sourceColumn: [Value3]")
    $lines.Add("")
    $lines.Add("    partition '_MOD Flex Flat Measures' = calculated")
    $lines.Add("        mode: import")
    $lines.Add("        source =")
    $lines.Add("                {")
    $lines.Add(($rows -join ",`r`n"))
    $lines.Add("                }")

    return (($lines -join "`r`n") + "`r`n")
}

function New-PbiFlexPivotInputsTemplate {
    param([Parameter(Mandatory = $true)]$MeasureItems)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD Flex Pivot Inputs'")
    $lines.Add("`tisHidden")
    $lines.Add("")

    for ($index = 0; $index -lt $MeasureItems.Count; $index++) {
        $item = $MeasureItems[$index]
        $measureOrdinal = $index + 1
        $lines.Add(("`tmeasure 'Flex Input Metric {0}' = [{1}]" -f $measureOrdinal, $item.bindingKey))
        $lines.Add("")
    }

    $lines.Add("`tcolumn Column")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [Column]")
    $lines.Add("")
    $lines.Add("`tpartition '_MOD Flex Pivot Inputs' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource = Row(""Column"", BLANK())")

    return ($lines -join "`r`n")
}

function New-PbiFlexPivotMeasureSelectorTemplate {
    param([Parameter(Mandatory = $true)]$MeasureItems)

    $rows = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $MeasureItems.Count; $index++) {
        $item = $MeasureItems[$index]
        $measureOrdinal = $index + 1
        $rows.Add(('                {"metric_' + $measureOrdinal + '", "{{bindingLabel:' + [string]$item.bindingKey + '}}", "Metric", ' + $measureOrdinal + '}'))
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD Flex Pivot Selector'")
    $lines.Add("    isHidden")
    $lines.Add("")
    $lines.Add("    column MeasureKey")
    $lines.Add("        isHidden")
    $lines.Add("        summarizeBy: none")
    $lines.Add("        isNameInferred")
    $lines.Add("        sourceColumn: [MeasureKey]")
    $lines.Add("")
    $lines.Add("    column DisplayLabel")
    $lines.Add("        summarizeBy: none")
    $lines.Add("        sortByColumn: MeasureSort")
    $lines.Add("        isNameInferred")
    $lines.Add("        sourceColumn: [DisplayLabel]")
    $lines.Add("")
    $lines.Add("    column Domain")
    $lines.Add("        summarizeBy: none")
    $lines.Add("        isNameInferred")
    $lines.Add("        sourceColumn: [Domain]")
    $lines.Add("")
    $lines.Add("    column MeasureSort")
    $lines.Add("        isHidden")
    $lines.Add("        formatString: 0")
    $lines.Add("        summarizeBy: none")
    $lines.Add("        isNameInferred")
    $lines.Add("        sourceColumn: [MeasureSort]")
    $lines.Add("")
    $lines.Add("    partition '_MOD Flex Pivot Selector' = calculated")
    $lines.Add("        mode: import")
    $lines.Add('        source = ```')
    $lines.Add("                DATATABLE(")
    $lines.Add('                    "MeasureKey", STRING,')
    $lines.Add('                    "DisplayLabel", STRING,')
    $lines.Add('                    "Domain", STRING,')
    $lines.Add('                    "MeasureSort", INTEGER,')
    $lines.Add("                    {")
    $lines.Add(($rows -join ",`r`n"))
    $lines.Add("                    }")
    $lines.Add("                )")
    $lines.Add('                ```')

    return (($lines -join "`r`n") + "`r`n")
}

function New-PbiFlexPivotAxisTemplate {
    param([Parameter(Mandatory = $true)]$DimensionItems)

    $blocks = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $DimensionItems.Count; $index++) {
        $item = $DimensionItems[$index]
        $dimensionOrdinal = $index + 1
        $bindingTable = Get-PbiFlexDimensionBindingTableName -Item $item
        $blocks.Add(@(
                "				    SELECTCOLUMNS(",
                "				        FILTER(",
                ("				            VALUES({0}[Value])," -f $bindingTable),
                ("				            NOT ISBLANK({0}[Value])" -f $bindingTable),
                "				        ),",
                ("				        ""DimensionKey"", ""dimension_{0}""," -f $dimensionOrdinal),
                ("				        ""DimensionLabel"", ""{0}""," -f (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$item.bindingKey))),
                ("				        ""DimensionSort"", {0}," -f $dimensionOrdinal),
                ("				        ""AxisLabel"", {0}[Value]" -f $bindingTable),
                "				    )"
            ) -join "`r`n")
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD Flex Pivot Axis'")
    $lines.Add("`tisHidden")
    $lines.Add("")
    $lines.Add("`tcolumn DimensionKey")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [DimensionKey]")
    $lines.Add("")
    $lines.Add("`tcolumn DimensionLabel")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tsortByColumn: DimensionSort")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [DimensionLabel]")
    $lines.Add("")
    $lines.Add("`tcolumn DimensionSort")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [DimensionSort]")
    $lines.Add("")
    $lines.Add("`tcolumn AxisLabel")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [AxisLabel]")
    $lines.Add("")
    $lines.Add("`tpartition '_MOD Flex Pivot Axis' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource =")
    $lines.Add("`t`t`t`tUNION(")
    $lines.Add(($blocks -join ",`r`n"))
    $lines.Add("`t`t`t`t)")

    return (($lines -join "`r`n") + "`r`n")
}

function New-PbiFlexPivotMetricsTemplate {
    param(
        [Parameter(Mandatory = $true)]$MeasureItems,
        [Parameter(Mandatory = $true)]$DimensionItems
    )

    $measureSwitchRows = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $MeasureItems.Count; $index++) {
        $measureOrdinal = $index + 1
        $measureSwitchRows.Add(('			        "metric_{0}", [Flex Input Metric {0}]' -f $measureOrdinal))
    }

    $dimensionSwitchRows = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $DimensionItems.Count; $index++) {
        $item = $DimensionItems[$index]
        $dimensionOrdinal = $index + 1
        $bindingTable = Get-PbiFlexDimensionBindingTableName -Item $item
        $row = @(
            ('			    "dimension_{0}",' -f $dimensionOrdinal),
            '			        CALCULATE(',
            '			            BaseMetric,',
            ('			            KEEPFILTERS(TREATAS({{AxisValue}}, {0}[Value]))' -f $bindingTable),
            '			        )'
        ) -join "`r`n"
        $dimensionSwitchRows.Add($row.TrimEnd())
    }

    $fallbackLabel = if ($DimensionItems.Count -gt 0) {
        "{{bindingLabel:$($DimensionItems[0].bindingKey)}}"
    }
    else {
        "Selection"
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table 'MOD Flex Pivot'")
    $lines.Add("")
    $lines.Add("`tmeasure 'Flex Table Selected Value' =")
    $lines.Add("`t`t")
    $lines.Add("`t`tVAR SelectedMeasure = SELECTEDVALUE('_MOD Flex Pivot Selector'[MeasureKey])")
    $lines.Add("`t`tVAR AxisKey = SELECTEDVALUE('_MOD Flex Pivot Axis'[DimensionKey])")
    $lines.Add("`t`tVAR AxisValue = SELECTEDVALUE('_MOD Flex Pivot Axis'[AxisLabel])")
    $lines.Add("`t`tVAR BaseMetric =")
    $lines.Add("`t`t    SWITCH(")
    $lines.Add("`t`t        SelectedMeasure,")
    $lines.Add(($measureSwitchRows -join ",`r`n"))
    $lines.Add("`t`t        BLANK()")
    $lines.Add("`t`t    )")
    $lines.Add("`t`tRETURN")
    $lines.Add("`t`tSWITCH(")
    $lines.Add("`t`t    AxisKey,")
    $lines.Add(($dimensionSwitchRows -join ",`r`n"))
    $lines.Add("`t`t    BLANK()")
    $lines.Add("`t`t)")
    $lines.Add("`t`tdisplayFolder: Outputs")
    $lines.Add("")
    $lines.Add("`tmeasure 'Flex Table Row Has Data' =")
    $lines.Add("`t`t")
    $lines.Add("`t`tVAR NonBlankMeasureCount =")
    $lines.Add("`t`t    SUMX(")
    $lines.Add("`t`t        VALUES('_MOD Flex Pivot Selector'[MeasureKey]),")
    $lines.Add("`t`t        VAR CurrentMeasureKey = '_MOD Flex Pivot Selector'[MeasureKey]")
    $lines.Add("`t`t        RETURN")
    $lines.Add("`t`t            IF(")
    $lines.Add("`t`t                NOT ISBLANK(")
    $lines.Add("`t`t                    CALCULATE(")
    $lines.Add("`t`t                        [Flex Table Selected Value],")
    $lines.Add("`t`t                        TREATAS({CurrentMeasureKey}, '_MOD Flex Pivot Selector'[MeasureKey])")
    $lines.Add("`t`t                    )")
    $lines.Add("`t`t                ),")
    $lines.Add("`t`t                1,")
    $lines.Add("`t`t                0")
    $lines.Add("`t`t            )")
    $lines.Add("`t`t    )")
    $lines.Add("`t`tRETURN")
    $lines.Add("`t`tIF(NonBlankMeasureCount > 0, 1)")
    $lines.Add("`t`tdisplayFolder: Diagnostics")
    $lines.Add("")
    $lines.Add("`tmeasure 'Flex Table Title' =")
    $lines.Add("`t`t")
    $lines.Add("`t`tVAR SelectedDimensions =")
    $lines.Add("`t`t    CONCATENATEX(")
    $lines.Add("`t`t        VALUES('_MOD Flex Pivot Axis'[DimensionLabel]),")
    $lines.Add("`t`t        '_MOD Flex Pivot Axis'[DimensionLabel],")
    $lines.Add("`t`t        "", "",")
    $lines.Add("`t`t        '_MOD Flex Pivot Axis'[DimensionSort],")
    $lines.Add("`t`t        ASC")
    $lines.Add("`t`t    )")
    $lines.Add("`t`tRETURN")
    $lines.Add(("`t`t""Flexible Metrics Pivot | "" & COALESCE(SelectedDimensions, ""{0}"")" -f $fallbackLabel))
    $lines.Add("`t`tdisplayFolder: Presentation")
    $lines.Add("")
    $lines.Add("`tcolumn Column")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [Column]")
    $lines.Add("")
    $lines.Add("`tpartition 'MOD Flex Pivot' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource = Row(""Column"", BLANK())")

    return (($lines -join "`r`n") + "`r`n")
}

function Get-PbiFlexFlatColumnsSlicerContent {
    param(
        [Parameter(Mandatory = $true)][string]$TemplateContent,
        [Parameter(Mandatory = $true)]$DimensionItems
    )

    return $TemplateContent
}

function Get-PbiFlexFlatMeasuresSlicerContent {
    param(
        [Parameter(Mandatory = $true)][string]$TemplateContent,
        [Parameter(Mandatory = $true)]$MeasureItems
    )

    return $TemplateContent
}

function Get-PbiFlexFlatTableVisualContent {
    param(
        [Parameter(Mandatory = $true)][string]$TemplateContent,
        [Parameter(Mandatory = $true)]$DimensionItems,
        [Parameter(Mandatory = $true)]$MeasureItems
    )

    $visual = ConvertFrom-PbiJsonText -Text $TemplateContent
    $visibleDimensionCount = Get-PbiFlexVisibleCount -ItemCount $DimensionItems.Count -PreferredCount 2
    $visibleMeasureCount = Get-PbiFlexVisibleCount -ItemCount $MeasureItems.Count -PreferredCount 2
    $projections = @()

    for ($index = 0; $index -lt $visibleDimensionCount; $index++) {
        $item = $DimensionItems[$index]
        $bindingTable = Get-PbiFlexDimensionBindingTableName -Item $item
        $projections += @([ordered]@{
                field = [ordered]@{
                    Column = [ordered]@{
                        Expression = [ordered]@{
                            SourceRef = [ordered]@{
                                Entity = $bindingTable
                            }
                        }
                        Property = "Value"
                    }
                }
                queryRef = ("{0}.Value" -f $bindingTable)
                nativeQueryRef = (Get-PbiBindingTokenLiteral -Property "QueryRef" -BindingKey ([string]$item.bindingKey))
                displayName = (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$item.bindingKey))
            })
    }

    for ($index = 0; $index -lt $visibleMeasureCount; $index++) {
        $item = $MeasureItems[$index]
        $measureOrdinal = $index + 1
        $projections += @([ordered]@{
                field = [ordered]@{
                    Measure = [ordered]@{
                        Expression = [ordered]@{
                            SourceRef = [ordered]@{
                                Entity = "MOD Flex Flat"
                            }
                        }
                        Property = ("Flat Input Metric {0}" -f $measureOrdinal)
                    }
                }
                queryRef = ("MOD Flex Flat.Flat Input Metric {0}" -f $measureOrdinal)
                nativeQueryRef = (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$item.bindingKey))
                displayName = (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$item.bindingKey))
            })
    }

    $visual.visual.query.queryState.Values.projections = $projections
    $visual.visual.query.queryState.Values.fieldParameters = @(
        [ordered]@{
            parameterExpr = [ordered]@{
                Column = [ordered]@{
                    Expression = [ordered]@{
                        SourceRef = [ordered]@{
                            Entity = "_MOD Flex Flat Dimensions"
                        }
                    }
                    Property = "Flat Dimension"
                }
            }
            index = 0
            length = $visibleDimensionCount
        },
        [ordered]@{
            parameterExpr = [ordered]@{
                Column = [ordered]@{
                    Expression = [ordered]@{
                        SourceRef = [ordered]@{
                            Entity = "_MOD Flex Flat Measures"
                        }
                    }
                    Property = "Flat Measure"
                }
            }
            index = $visibleDimensionCount
            length = $visibleMeasureCount
        }
    )

    return (ConvertTo-PbiJsonText -InputObject $visual)
}

function New-PbiMetricSwitchInputsTemplate {
    param([Parameter(Mandatory = $true)]$MeasureItems)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD Metric Switch Inputs'")
    $lines.Add("`tisHidden")
    $lines.Add("")

    for ($index = 0; $index -lt $MeasureItems.Count; $index++) {
        $item = $MeasureItems[$index]
        $measureOrdinal = $index + 1
        $lines.Add(("`tmeasure 'Metric Switch Input Metric {0}' = [{1}]" -f $measureOrdinal, $item.bindingKey))
        $lines.Add("")
    }

    $lines.Add("`tcolumn Column")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [Column]")
    $lines.Add("")
    $lines.Add("`tpartition '_MOD Metric Switch Inputs' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource = Row(""Column"", BLANK())")

    return ($lines -join "`r`n")
}

function New-PbiMetricSwitchFacadeTemplate {
    param([Parameter(Mandatory = $true)]$MeasureItems)

    $selectorRows = New-Object System.Collections.Generic.List[string]
    $switchBranches = New-Object System.Collections.Generic.List[string]

    for ($index = 0; $index -lt $MeasureItems.Count; $index++) {
        $item = $MeasureItems[$index]
        $measureOrdinal = $index + 1
        $selectorRows.Add(('{{"metric_{0}", "{1}", {2}}}' -f $measureOrdinal, (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$item.bindingKey)), $measureOrdinal))
        $switchBranches.Add(('                "metric_{0}", ''_MOD Metric Switch Inputs''[Metric Switch Input Metric {1}]' -f $measureOrdinal, $measureOrdinal))
    }

    $partitionSource = ('DATATABLE("MetricKey", STRING, "MetricLabel", STRING, "SortOrder", INTEGER, {{ {0} }})' -f ($selectorRows -join ", "))

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table 'MOD Metric Switch'")
    $lines.Add("")
    $lines.Add("`tmeasure 'Metric Switch Selected Value' =")
    $lines.Add("`t`t`t")
    $lines.Add("`t`t`tSWITCH(")
    $lines.Add("`t`t`t    SELECTEDVALUE('MOD Metric Switch'[MetricKey], ""metric_1""),")
    $lines.Add(($switchBranches -join ",`r`n"))
    $lines.Add("`t`t`t)")
    $lines.Add("`t`tdisplayFolder: Outputs")
    $lines.Add("")
    $lines.Add("`tmeasure 'Metric Switch Selected Label' =")
    $lines.Add("`t`t`t")
    $lines.Add(("`t`t`tSELECTEDVALUE('MOD Metric Switch'[MetricLabel], ""{0}"")" -f (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$MeasureItems[0].bindingKey))))
    $lines.Add("`t`tdisplayFolder: Presentation")
    $lines.Add("")
    $lines.Add("`tmeasure 'Metric Switch Metric Count' = " + $MeasureItems.Count)
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Diagnostics")
    $lines.Add("")
    $lines.Add("`tcolumn MetricKey")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [MetricKey]")
    $lines.Add("")
    $lines.Add("`tcolumn MetricLabel")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [MetricLabel]")
    $lines.Add("`t`tsortByColumn: SortOrder")
    $lines.Add("")
    $lines.Add("`tcolumn SortOrder")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [SortOrder]")
    $lines.Add("")
    $lines.Add("`tpartition 'MOD Metric Switch' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add(("`t`tsource = {0}" -f $partitionSource))

    return ($lines -join "`r`n")
}

function Get-PbiFlexPivotDimensionSlicerContent {
    param(
        [Parameter(Mandatory = $true)][string]$TemplateContent,
        [Parameter(Mandatory = $true)]$DimensionItems
    )

    return $TemplateContent
}

function Get-PbiFlexPivotMeasureSlicerContent {
    param(
        [Parameter(Mandatory = $true)][string]$TemplateContent,
        [Parameter(Mandatory = $true)]$MeasureItems
    )

    return $TemplateContent
}

function Get-PbiRenderedFlexReportFiles {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$ResolvedMappings,
        [Parameter(Mandatory = $true)][scriptblock]$DynamicContentResolver
    )

    $sourceReportPath = Join-Path $Module.PackageRoot "report"
    $destinationPagePath = Get-PbiPageDestinationRoot -Project $Project -PageName $Manifest.provides.reportPage.name
    $mappings = @()

    foreach ($sourceFile in (Get-ChildItem -Path $sourceReportPath -Recurse -File -ErrorAction SilentlyContinue)) {
        $relativeFilePath = (Get-PbiRelativePath -BasePath $sourceReportPath -Path $sourceFile.FullName).Replace("/", "\")
        $destinationFilePath = Join-Path $destinationPagePath $relativeFilePath
        $sourceContent = Get-Content -Path $sourceFile.FullName -Raw
        $dynamicContent = & $DynamicContentResolver $relativeFilePath $sourceContent
        $contentToRender = if ($dynamicContent) { $dynamicContent } else { $sourceContent }
        $finalContent = Convert-PbiTextWithResolvedMappings -Text $contentToRender -ResolvedMappings $ResolvedMappings
        $mappings += (New-PbiRenderedModuleFileMapping -SourcePath $sourceFile.FullName -DestinationPath $destinationFilePath -RelativePath (Get-PbiRelativePath -BasePath $Project.ProjectRoot -Path $destinationFilePath) -SourceContent $finalContent)
    }

    return @($mappings)
}

function Get-PbiRenderedFlexFlatSemanticAssets {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$ResolvedMappings
    )

    $dimensionItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "dimensions")
    $measureItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "measures")
    $tableTemplates = [ordered]@{
        "MOD Flex Flat"     = (New-PbiFlexFlatInputsTemplate -MeasureItems $measureItems)
        "_MOD Flex Flat Dimensions" = (New-PbiFlexFlatDimensionsTemplate -DimensionItems $dimensionItems)
        "_MOD Flex Flat Measures"   = (New-PbiFlexFlatMeasuresTemplate -MeasureItems $measureItems)
    }

    $mappings = @()
    foreach ($tableName in @($Manifest.provides.semanticTables)) {
        $destinationPath = Get-PbiTableDefinitionPath -Project $Project -TableName $tableName
        $sourcePath = Join-Path (Join-Path $Module.PackageRoot "semantic") ($tableName + ".tmdl")
        $renderedContent = Convert-PbiTextWithResolvedMappings -Text $tableTemplates[$tableName] -ResolvedMappings $ResolvedMappings
        $mappings += (New-PbiRenderedModuleFileMapping -TableName $tableName -SourcePath $sourcePath -DestinationPath $destinationPath -RelativePath (Get-PbiRelativePath -BasePath $Project.ProjectRoot -Path $destinationPath) -SourceContent $renderedContent)
    }

    return @($mappings)
}

function Get-PbiRenderedFlexFlatReportAssets {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$ResolvedMappings
    )

    $dimensionItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "dimensions")
    $measureItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "measures")

    return @(Get-PbiRenderedFlexReportFiles -Project $Project -Module $Module -Manifest $Manifest -ResolvedMappings $ResolvedMappings -DynamicContentResolver {
            param($RelativeFilePath, $TemplateContent)

            switch ($RelativeFilePath) {
                "visuals\flex_flat_columns_slicer\visual.json" { return (Get-PbiFlexFlatColumnsSlicerContent -TemplateContent $TemplateContent -DimensionItems $dimensionItems) }
                "visuals\flex_flat_measures_slicer\visual.json" { return (Get-PbiFlexFlatMeasuresSlicerContent -TemplateContent $TemplateContent -MeasureItems $measureItems) }
                "visuals\flex_flat_table\visual.json" { return (Get-PbiFlexFlatTableVisualContent -TemplateContent $TemplateContent -DimensionItems $dimensionItems -MeasureItems $measureItems) }
                default { return $TemplateContent }
            }
        })
}

function Get-PbiRenderedFlexPivotSemanticAssets {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$ResolvedMappings
    )

    $dimensionItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "dimensions")
    $measureItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "measures")
    $tableTemplates = [ordered]@{
        "_MOD Flex Pivot Inputs"           = (New-PbiFlexPivotInputsTemplate -MeasureItems $measureItems)
        "_MOD Flex Pivot Selector" = (New-PbiFlexPivotMeasureSelectorTemplate -MeasureItems $measureItems)
        "_MOD Flex Pivot Axis"             = (New-PbiFlexPivotAxisTemplate -DimensionItems $dimensionItems)
        "MOD Flex Pivot"          = (New-PbiFlexPivotMetricsTemplate -MeasureItems $measureItems -DimensionItems $dimensionItems)
    }

    $mappings = @()
    foreach ($tableName in @($Manifest.provides.semanticTables)) {
        $destinationPath = Get-PbiTableDefinitionPath -Project $Project -TableName $tableName
        $sourcePath = Join-Path (Join-Path $Module.PackageRoot "semantic") ($tableName + ".tmdl")
        $renderedContent = Convert-PbiTextWithResolvedMappings -Text $tableTemplates[$tableName] -ResolvedMappings $ResolvedMappings
        $mappings += (New-PbiRenderedModuleFileMapping -TableName $tableName -SourcePath $sourcePath -DestinationPath $destinationPath -RelativePath (Get-PbiRelativePath -BasePath $Project.ProjectRoot -Path $destinationPath) -SourceContent $renderedContent)
    }

    return @($mappings)
}

function Get-PbiRenderedFlexPivotReportAssets {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$ResolvedMappings
    )

    $dimensionItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "dimensions")
    $measureItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "measures")

    return @(Get-PbiRenderedFlexReportFiles -Project $Project -Module $Module -Manifest $Manifest -ResolvedMappings $ResolvedMappings -DynamicContentResolver {
            param($RelativeFilePath, $TemplateContent)

            switch ($RelativeFilePath) {
                "visuals\flex_table_dimension_slicer\visual.json" { return (Get-PbiFlexPivotDimensionSlicerContent -TemplateContent $TemplateContent -DimensionItems $dimensionItems) }
                "visuals\flex_table_measure_slicer\visual.json" { return (Get-PbiFlexPivotMeasureSlicerContent -TemplateContent $TemplateContent -MeasureItems $measureItems) }
                default { return $TemplateContent }
            }
        })
}

function Get-PbiRenderedMetricSwitchSemanticAssets {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$ResolvedMappings
    )

    $measureItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "measures")
    $tableTemplates = [ordered]@{
        "_MOD Metric Switch Inputs" = (New-PbiMetricSwitchInputsTemplate -MeasureItems $measureItems)
        "MOD Metric Switch"         = (New-PbiMetricSwitchFacadeTemplate -MeasureItems $measureItems)
    }

    $mappings = @()
    foreach ($tableName in @($Manifest.provides.semanticTables)) {
        $destinationPath = Get-PbiTableDefinitionPath -Project $Project -TableName $tableName
        $sourcePath = Join-Path (Join-Path $Module.PackageRoot "semantic") ($tableName + ".tmdl")
        $renderedContent = Convert-PbiTextWithResolvedMappings -Text $tableTemplates[$tableName] -ResolvedMappings $ResolvedMappings
        $mappings += (New-PbiRenderedModuleFileMapping -TableName $tableName -SourcePath $sourcePath -DestinationPath $destinationPath -RelativePath (Get-PbiRelativePath -BasePath $Project.ProjectRoot -Path $destinationPath) -SourceContent $renderedContent)
    }

    return @($mappings)
}

function New-PbiTopNDriverInputsTemplate {
    param([Parameter(Mandatory = $true)]$MeasureItems)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD TopN Driver Inputs'")
    $lines.Add("`tisHidden")
    $lines.Add("")

    for ($index = 0; $index -lt $MeasureItems.Count; $index++) {
        $item = $MeasureItems[$index]
        $measureOrdinal = $index + 1
        $lines.Add(("`tmeasure 'TopN Driver Input Metric {0}' = [{1}]" -f $measureOrdinal, $item.bindingKey))
        $lines.Add("")
    }

    $lines.Add("`tcolumn Column")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [Column]")
    $lines.Add("")
    $lines.Add("`tpartition '_MOD TopN Driver Inputs' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource = Row(""Column"", BLANK())")

    return ($lines -join "`r`n")
}

function New-PbiTopNDriverGrainSelectorTemplate {
    param([Parameter(Mandatory = $true)]$DimensionItems)

    $rows = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $DimensionItems.Count; $index++) {
        $item = $DimensionItems[$index]
        $dimensionOrdinal = $index + 1
        $rows.Add(('{{"dimension_{0}", "{1}", {2}}}' -f $dimensionOrdinal, (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$item.bindingKey)), $dimensionOrdinal))
    }

    $partitionSource = ('DATATABLE("GrainKey", STRING, "GrainLabel", STRING, "GrainSort", INTEGER, {{ {0} }})' -f ($rows -join ", "))

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD TopN Driver Grains'")
    $lines.Add("`tisHidden")
    $lines.Add("")
    $lines.Add("`tcolumn GrainKey")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [GrainKey]")
    $lines.Add("")
    $lines.Add("`tcolumn GrainLabel")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tsourceColumn: [GrainLabel]")
    $lines.Add("`t`tsortByColumn: GrainSort")
    $lines.Add("")
    $lines.Add("`tcolumn GrainSort")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [GrainSort]")
    $lines.Add("")
    $lines.Add("`tpartition '_MOD TopN Driver Grains' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add(("`t`tsource = {0}" -f $partitionSource))

    return ($lines -join "`r`n")
}

function New-PbiTopNDriverMetricSelectorTemplate {
    param([Parameter(Mandatory = $true)]$MeasureItems)

    $rows = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $MeasureItems.Count; $index++) {
        $item = $MeasureItems[$index]
        $measureOrdinal = $index + 1
        $rows.Add(('{{"metric_{0}", "{1}", {2}}}' -f $measureOrdinal, (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$item.bindingKey)), $measureOrdinal))
    }

    $partitionSource = ('DATATABLE("MetricKey", STRING, "MetricLabel", STRING, "MetricSort", INTEGER, {{ {0} }})' -f ($rows -join ", "))

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD TopN Driver Metrics'")
    $lines.Add("`tisHidden")
    $lines.Add("")
    $lines.Add("`tcolumn MetricKey")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [MetricKey]")
    $lines.Add("")
    $lines.Add("`tcolumn MetricLabel")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tsourceColumn: [MetricLabel]")
    $lines.Add("`t`tsortByColumn: MetricSort")
    $lines.Add("")
    $lines.Add("`tcolumn MetricSort")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [MetricSort]")
    $lines.Add("")
    $lines.Add("`tpartition '_MOD TopN Driver Metrics' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add(("`t`tsource = {0}" -f $partitionSource))

    return ($lines -join "`r`n")
}

function New-PbiTopNDriverTargetSelectorTemplate {
    param([Parameter(Mandatory = $true)]$DimensionItems)

    $placeholderRows = New-Object System.Collections.Generic.List[string]
    $targetBlocks = New-Object System.Collections.Generic.List[string]

    for ($index = 0; $index -lt $DimensionItems.Count; $index++) {
        $item = $DimensionItems[$index]
        $dimensionOrdinal = $index + 1
        $dimensionKey = ("dimension_{0}" -f $dimensionOrdinal)
        $dimensionLabel = Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$item.bindingKey)

        $placeholderRows.Add(('                        {{"{0}", "{1} | (Select target)", "{1}", "(Select target)"}}' -f $dimensionKey, $dimensionLabel))

        $targetBlocks.Add((@(
                    "                SELECTCOLUMNS(",
                    "                    FILTER(",
                    ("                        VALUES({0})," -f $item.bindingKey),
                    ("                        NOT ISBLANK({0})" -f $item.bindingKey),
                    "                    ),",
                    ('                    "TargetGrainKey", "{0}",' -f $dimensionKey),
                    ('                    "TargetSelector", "{0} | " & ({1} & ""),' -f $dimensionLabel, $item.bindingKey),
                    ('                    "TargetGrainLabel", "{0}",' -f $dimensionLabel),
                    ('                    "TargetEntity", {0} & ""' -f $item.bindingKey),
                    "                )"
                ) -join "`r`n"))
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD TopN Driver Targets'")
    $lines.Add("`tisHidden")
    $lines.Add("")
    $lines.Add("`tcolumn TargetGrainKey")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [TargetGrainKey]")
    $lines.Add("")
    $lines.Add("`tcolumn TargetSelector")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [TargetSelector]")
    $lines.Add("")
    $lines.Add("`tcolumn TargetGrainLabel")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [TargetGrainLabel]")
    $lines.Add("")
    $lines.Add("`tcolumn TargetEntity")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [TargetEntity]")
    $lines.Add("")
    $lines.Add("`tpartition '_MOD TopN Driver Targets' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource = " + '```')
    $lines.Add("                VAR Placeholder =")
    $lines.Add("                    DATATABLE(")
    $lines.Add("                        ""TargetGrainKey"", STRING,")
    $lines.Add("                        ""TargetSelector"", STRING,")
    $lines.Add("                        ""TargetGrainLabel"", STRING,")
    $lines.Add("                        ""TargetEntity"", STRING,")
    $lines.Add("                        {")
    $lines.Add(($placeholderRows -join ",`r`n"))
    $lines.Add("                        }")
    $lines.Add("                    )")
    $lines.Add("                RETURN")
    $lines.Add("                UNION(")
    $lines.Add("                    Placeholder,")
    $lines.Add(($targetBlocks -join ",`r`n"))
    $lines.Add("                )")
    $lines.Add("                " + '```')

    return (($lines -join "`r`n") + "`r`n")
}

function New-PbiTopNDriverTopNSelectorTemplate {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD TopN Driver N'")
    $lines.Add("`tisHidden")
    $lines.Add("")
    $lines.Add("`tcolumn TopN")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [Value]")
    $lines.Add("")
    $lines.Add("`tpartition '_MOD TopN Driver N' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource = GENERATESERIES(1, 20, 1)")

    return ($lines -join "`r`n")
}

function New-PbiTopNDriverFacadeTemplate {
    param(
        [Parameter(Mandatory = $true)]$DimensionItems,
        [Parameter(Mandatory = $true)]$MeasureItems
    )

    $defaultDimensionLabel = Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$DimensionItems[0].bindingKey)
    $defaultMetricLabel = Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$MeasureItems[0].bindingKey)
    $metricSwitchBranches = New-Object System.Collections.Generic.List[string]
    $currentEntityBranches = New-Object System.Collections.Generic.List[string]
    $rankBranches = New-Object System.Collections.Generic.List[string]
    $rankExcludingBranches = New-Object System.Collections.Generic.List[string]

    for ($index = 0; $index -lt $MeasureItems.Count; $index++) {
        $measureOrdinal = $index + 1
        $metricSwitchBranches.Add(('            "metric_{0}", ''_MOD TopN Driver Inputs''[TopN Driver Input Metric {1}]' -f $measureOrdinal, $measureOrdinal))
    }

    for ($index = 0; $index -lt $DimensionItems.Count; $index++) {
        $item = $DimensionItems[$index]
        $dimensionOrdinal = $index + 1
        $dimensionKey = ("dimension_{0}" -f $dimensionOrdinal)
        $columnReference = [string]$item.bindingKey

        $currentEntityBranches.Add(('            "{0}", SELECTEDVALUE({1}) & ""' -f $dimensionKey, $columnReference))
        $rankBranches.Add((@(
                    ('            "{0}",' -f $dimensionKey),
                    ('                VAR CurrentEntity = SELECTEDVALUE({0})' -f $columnReference),
                    "                RETURN",
                    "                    IF(",
                    "                        ISBLANK(CurrentEntity),",
                    "                        BLANK(),",
                    "                        RANKX(",
                    ('                            ALLSELECTED({0}),' -f $columnReference),
                    "                            CALCULATE([TopN Driver Selected Metric Value]),",
                    "                            ,",
                    "                            DESC,",
                    "                            DENSE",
                    "                        )",
                    "                    )"
                ) -join "`r`n"))
        $rankExcludingBranches.Add((@(
                    ('            "{0}",' -f $dimensionKey),
                    ('                VAR CurrentEntity = SELECTEDVALUE({0})' -f $columnReference),
                    "                RETURN",
                    "                    IF(",
                    "                        ISBLANK(CurrentEntity),",
                    "                        BLANK(),",
                    "                        RANKX(",
                    "                            FILTER(",
                    ('                                ALLSELECTED({0}),' -f $columnReference),
                    ('                                ({0} & "") <> TargetEntity' -f $columnReference),
                    "                            ),",
                    "                            CALCULATE([TopN Driver Selected Metric Value]),",
                    "                            ,",
                    "                            DESC,",
                    "                            DENSE",
                    "                        )",
                    "                    )"
                ) -join "`r`n"))
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table 'MOD TopN Driver'")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Selected N' =")
    $lines.Add("`t`tSELECTEDVALUE('_MOD TopN Driver N'[TopN], 5)")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Selected Grain Key' =")
    $lines.Add("`t`tSELECTEDVALUE('_MOD TopN Driver Grains'[GrainKey], ""dimension_1"")")
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Selected Grain Label' =")
    $lines.Add(("`t`tSELECTEDVALUE('_MOD TopN Driver Grains'[GrainLabel], ""{0}"")" -f $defaultDimensionLabel))
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Selected Metric Key' =")
    $lines.Add("`t`tSELECTEDVALUE('_MOD TopN Driver Metrics'[MetricKey], ""metric_1"")")
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Selected Metric Label' =")
    $lines.Add(("`t`tSELECTEDVALUE('_MOD TopN Driver Metrics'[MetricLabel], ""{0}"")" -f $defaultMetricLabel))
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Selected Target Grain Key' =")
    $lines.Add("`t`tSELECTEDVALUE('_MOD TopN Driver Targets'[TargetGrainKey])")
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Selected Target Grain Label' =")
    $lines.Add("`t`tSELECTEDVALUE('_MOD TopN Driver Targets'[TargetGrainLabel])")
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Selected Target Entity' =")
    $lines.Add("`t`tVAR TargetEntity = SELECTEDVALUE('_MOD TopN Driver Targets'[TargetEntity])")
    $lines.Add("`t`tRETURN")
    $lines.Add("`t`tIF(TargetEntity = ""(Select target)"", BLANK(), TargetEntity)")
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Is Target Selected' =")
    $lines.Add("`t`tVAR TargetEntity = [TopN Driver Selected Target Entity]")
    $lines.Add("`t`tVAR TargetGrainKey = [TopN Driver Selected Target Grain Key]")
    $lines.Add("`t`tVAR ActiveGrainKey = [TopN Driver Selected Grain Key]")
    $lines.Add("`t`tRETURN")
    $lines.Add("`t`tIF(NOT ISBLANK(TargetEntity) && TargetGrainKey = ActiveGrainKey, 1, 0)")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Selected Metric Value' =")
    $lines.Add("`t`tSWITCH(")
    $lines.Add("`t`t    [TopN Driver Selected Metric Key],")
    $lines.Add(($metricSwitchBranches -join ",`r`n"))
    $lines.Add("`t`t)")
    $lines.Add("`t`tdisplayFolder: Outputs")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Current Entity' =")
    $lines.Add("`t`tSWITCH(")
    $lines.Add("`t`t    [TopN Driver Selected Grain Key],")
    $lines.Add(($currentEntityBranches -join ",`r`n"))
    $lines.Add("`t`t    BLANK()")
    $lines.Add("`t`t)")
    $lines.Add("`t`tdisplayFolder: Outputs")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Rank' =")
    $lines.Add("`t`tSWITCH(")
    $lines.Add("`t`t    [TopN Driver Selected Grain Key],")
    $lines.Add(($rankBranches -join ",`r`n"))
    $lines.Add("`t`t    BLANK()")
    $lines.Add("`t`t)")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Ranking")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Rank Excluding Target' =")
    $lines.Add("`t`tVAR TargetEntity = [TopN Driver Selected Target Entity]")
    $lines.Add("`t`tRETURN")
    $lines.Add("`t`tSWITCH(")
    $lines.Add("`t`t    [TopN Driver Selected Grain Key],")
    $lines.Add(($rankExcludingBranches -join ",`r`n"))
    $lines.Add("`t`t    BLANK()")
    $lines.Add("`t`t)")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Ranking")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Show In Ranked Set' =")
    $lines.Add("`t`tVAR SelectedN = [TopN Driver Selected N]")
    $lines.Add("`t`tVAR CurrentEntity = [TopN Driver Current Entity]")
    $lines.Add("`t`tRETURN")
    $lines.Add("`t`tIF(")
    $lines.Add("`t`t    ISBLANK(CurrentEntity),")
    $lines.Add("`t`t    BLANK(),")
    $lines.Add("`t`t    IF(")
    $lines.Add("`t`t        [TopN Driver Is Target Selected] = 0,")
    $lines.Add("`t`t        IF([TopN Driver Rank] <= SelectedN, 1, 0),")
    $lines.Add("`t`t        IF(")
    $lines.Add("`t`t            CurrentEntity = [TopN Driver Selected Target Entity],")
    $lines.Add("`t`t            1,")
    $lines.Add("`t`t            IF([TopN Driver Rank Excluding Target] <= SelectedN - 1, 1, 0)")
    $lines.Add("`t`t        )")
    $lines.Add("`t`t    )")
    $lines.Add("`t`t)")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Ranking")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Is Target Row' =")
    $lines.Add("`t`tIF(")
    $lines.Add("`t`t    [TopN Driver Is Target Selected] = 1 && [TopN Driver Current Entity] = [TopN Driver Selected Target Entity],")
    $lines.Add("`t`t    1,")
    $lines.Add("`t`t    0")
    $lines.Add("`t`t)")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Ranking")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Target Badge' =")
    $lines.Add("`t`tIF([TopN Driver Is Target Row] = 1, ""★"", BLANK())")
    $lines.Add("`t`tdisplayFolder: Presentation")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Target Status' =")
    $lines.Add("`t`tVAR TargetEntity = [TopN Driver Selected Target Entity]")
    $lines.Add("`t`tVAR TargetGrainKey = [TopN Driver Selected Target Grain Key]")
    $lines.Add("`t`tRETURN")
    $lines.Add("`t`tIF(")
    $lines.Add("`t`t    NOT ISBLANK(TargetEntity) && TargetGrainKey <> [TopN Driver Selected Grain Key],")
    $lines.Add("`t`t    ""Target '"" & TargetEntity & ""' belongs to "" & [TopN Driver Selected Target Grain Label] & "" while the active ranking grain is "" & [TopN Driver Selected Grain Label] & ""."",")
    $lines.Add("`t`t    BLANK()")
    $lines.Add("`t`t)")
    $lines.Add("`t`tdisplayFolder: Diagnostics")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Title' =")
    $lines.Add("`t`t""Top "" & FORMAT([TopN Driver Selected N], ""0"") & "" | "" & [TopN Driver Selected Metric Label] & "" | "" & [TopN Driver Selected Grain Label] & IF([TopN Driver Is Target Selected] = 1, "" | Target: "" & [TopN Driver Selected Target Entity], """")")
    $lines.Add("`t`tdisplayFolder: Presentation")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Metric Count' = " + $MeasureItems.Count)
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Diagnostics")
    $lines.Add("")
    $lines.Add("`tmeasure 'TopN Driver Grain Count' = " + $DimensionItems.Count)
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Diagnostics")
    $lines.Add("")
    $lines.Add("`tcolumn Column")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [Column]")
    $lines.Add("")
    $lines.Add("`tpartition 'MOD TopN Driver' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource = Row(""Column"", BLANK())")

    return (($lines -join "`r`n") + "`r`n")
}

function Get-PbiRenderedTopNDriverSemanticAssets {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$ResolvedMappings
    )

    $dimensionItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "dimensions")
    $measureItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "measures")
    $tableTemplates = [ordered]@{
        "_MOD TopN Driver Inputs"  = (New-PbiTopNDriverInputsTemplate -MeasureItems $measureItems)
        "_MOD TopN Driver Grains"  = (New-PbiTopNDriverGrainSelectorTemplate -DimensionItems $dimensionItems)
        "_MOD TopN Driver Metrics" = (New-PbiTopNDriverMetricSelectorTemplate -MeasureItems $measureItems)
        "_MOD TopN Driver Targets" = (New-PbiTopNDriverTargetSelectorTemplate -DimensionItems $dimensionItems)
        "_MOD TopN Driver N"       = (New-PbiTopNDriverTopNSelectorTemplate)
        "MOD TopN Driver"          = (New-PbiTopNDriverFacadeTemplate -DimensionItems $dimensionItems -MeasureItems $measureItems)
    }

    $mappings = @()
    foreach ($tableName in @($Manifest.provides.semanticTables)) {
        $destinationPath = Get-PbiTableDefinitionPath -Project $Project -TableName $tableName
        $sourcePath = Join-Path (Join-Path $Module.PackageRoot "semantic") ($tableName + ".tmdl")
        $renderedContent = Convert-PbiTextWithResolvedMappings -Text $tableTemplates[$tableName] -ResolvedMappings $ResolvedMappings
        $mappings += (New-PbiRenderedModuleFileMapping -TableName $tableName -SourcePath $sourcePath -DestinationPath $destinationPath -RelativePath (Get-PbiRelativePath -BasePath $Project.ProjectRoot -Path $destinationPath) -SourceContent $renderedContent)
    }

    return @($mappings)
}

function Get-PbiResolvedMeasureBindingIfPresent {
    param(
        [Parameter(Mandatory = $true)]$ResolvedMappings,
        [Parameter(Mandatory = $true)][string]$BindingKey
    )

    $measureMappings = Get-PbiResolvedMappingSection -ResolvedMappings $ResolvedMappings -SectionName "coreMeasures"
    $value = ""
    if ($measureMappings -is [System.Collections.IDictionary]) {
        foreach ($key in @($measureMappings.Keys)) {
            if ([string]$key -ne $BindingKey) {
                continue
            }

            $value = [string]$measureMappings[$key]
            break
        }
    }
    elseif ($measureMappings -and $measureMappings.PSObject.Properties[$BindingKey]) {
        $value = [string]$measureMappings.PSObject.Properties[$BindingKey].Value
    }

    if ([string]::IsNullOrWhiteSpace($value) -or ($value -eq $BindingKey)) {
        return ""
    }

    return $value
}

function ConvertTo-PbiDaxStringLiteral {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value)

    $escapedValue = $Value.Replace('"', '""')
    return ('"' + $escapedValue + '"')
}

function Get-PbiCompetitiveBenchmarkPresetBindings {
    param([Parameter(Mandatory = $true)]$ResolvedMappings)

    $presets = @()
    foreach ($presetOrdinal in 1..4) {
        $xBindingKey = ("MOD_BIND_PRESET_{0}_X_MEASURE" -f $presetOrdinal)
        $yBindingKey = ("MOD_BIND_PRESET_{0}_Y_MEASURE" -f $presetOrdinal)
        $sizeBindingKey = ("MOD_BIND_PRESET_{0}_SIZE_MEASURE" -f $presetOrdinal)

        $xMeasure = Get-PbiResolvedMeasureBindingIfPresent -ResolvedMappings $ResolvedMappings -BindingKey $xBindingKey
        $yMeasure = Get-PbiResolvedMeasureBindingIfPresent -ResolvedMappings $ResolvedMappings -BindingKey $yBindingKey
        $sizeMeasure = Get-PbiResolvedMeasureBindingIfPresent -ResolvedMappings $ResolvedMappings -BindingKey $sizeBindingKey

        if ([string]::IsNullOrWhiteSpace($xMeasure) -or [string]::IsNullOrWhiteSpace($yMeasure) -or [string]::IsNullOrWhiteSpace($sizeMeasure)) {
            continue
        }

        $presets += [PSCustomObject]@{
            Ordinal        = $presetOrdinal
            XBindingKey    = $xBindingKey
            YBindingKey    = $yBindingKey
            SizeBindingKey = $sizeBindingKey
        }
    }

    return @($presets)
}

function New-PbiCompetitiveBenchmarkInputsTemplate {
    param(
        [Parameter(Mandatory = $true)]$PresetBindings,
        [Parameter(Mandatory = $true)]$SelectorMeasureItems
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD Competitive Benchmark Inputs'")
    $lines.Add("`tisHidden")
    $lines.Add("")

    foreach ($preset in @($PresetBindings)) {
        $presetOrdinal = [int]$preset.Ordinal
        $xBindingKey = [string]$preset.XBindingKey
        $yBindingKey = [string]$preset.YBindingKey
        $sizeBindingKey = [string]$preset.SizeBindingKey

        $lines.Add(("`tmeasure 'Competitive Benchmark Preset {0} X Input' = [{1}]" -f $presetOrdinal, $xBindingKey))
        $lines.Add("")
        $lines.Add(("`tmeasure 'Competitive Benchmark Preset {0} Y Input' = [{1}]" -f $presetOrdinal, $yBindingKey))
        $lines.Add("")
        $lines.Add(("`tmeasure 'Competitive Benchmark Preset {0} Size Input' = [{1}]" -f $presetOrdinal, $sizeBindingKey))
        $lines.Add("")
    }

    for ($index = 0; $index -lt $SelectorMeasureItems.Count; $index++) {
        $item = $SelectorMeasureItems[$index]
        $measureOrdinal = $index + 1
        $bindingKey = [string]$item.bindingKey
        $lines.Add(("`tmeasure 'Competitive Benchmark Selector Metric {0}' = [{1}]" -f $measureOrdinal, $bindingKey))
        $lines.Add("")
    }

    $lines.Add("`tcolumn Column")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [Column]")
    $lines.Add("")
    $lines.Add("`tpartition '_MOD Competitive Benchmark Inputs' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource = Row(""Column"", BLANK())")

    return ($lines -join "`r`n")
}

function New-PbiCompetitiveBenchmarkMetricSelectorTemplate {
    param([Parameter(Mandatory = $true)]$SelectorMeasureItems)

    $rows = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $SelectorMeasureItems.Count; $index++) {
        $item = $SelectorMeasureItems[$index]
        $measureOrdinal = $index + 1
        $metricKey = ('metric_{0}' -f $measureOrdinal)
        $metricLabelLiteral = ConvertTo-PbiDaxStringLiteral -Value (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$item.bindingKey))
        $rows.Add(('{' + (ConvertTo-PbiDaxStringLiteral -Value $metricKey) + ', ' + $metricLabelLiteral + ', ' + $measureOrdinal + '}'))
    }

    $partitionSource = ('DATATABLE("MetricKey", STRING, "MetricLabel", STRING, "MetricSort", INTEGER, { ' + ($rows -join ", ") + ' })')

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD Competitive Benchmark Metrics'")
    $lines.Add("`tisHidden")
    $lines.Add("")
    $lines.Add("`tcolumn MetricKey")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [MetricKey]")
    $lines.Add("")
    $lines.Add("`tcolumn MetricLabel")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [MetricLabel]")
    $lines.Add("`t`tsortByColumn: MetricSort")
    $lines.Add("")
    $lines.Add("`tcolumn MetricSort")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [MetricSort]")
    $lines.Add("")
    $lines.Add("`tpartition '_MOD Competitive Benchmark Metrics' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add(("`t`tsource = {0}" -f $partitionSource))

    return ($lines -join "`r`n")
}

function New-PbiCompetitiveBenchmarkPresetTableTemplate {
    param([Parameter(Mandatory = $true)]$PresetBindings)

    $rows = New-Object System.Collections.Generic.List[string]
    foreach ($preset in @($PresetBindings)) {
        $presetOrdinal = [int]$preset.Ordinal
        $xLabel = Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$preset.XBindingKey)
        $yLabel = Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$preset.YBindingKey)
        $sizeLabel = Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$preset.SizeBindingKey)
        $presetNameLiteral = ConvertTo-PbiDaxStringLiteral -Value ('{0} vs {1}' -f $xLabel, $yLabel)
        $rows.Add(('{' + $presetOrdinal + ', ' + $presetNameLiteral + ', ' + $presetOrdinal + ', ' + (ConvertTo-PbiDaxStringLiteral -Value $xLabel) + ', ' + (ConvertTo-PbiDaxStringLiteral -Value $yLabel) + ', ' + (ConvertTo-PbiDaxStringLiteral -Value $sizeLabel) + '}'))
    }

    $partitionSource = ('DATATABLE("PresetKey", INTEGER, "PresetName", STRING, "PresetSort", INTEGER, "XAxisLabel", STRING, "YAxisLabel", STRING, "SizeLabel", STRING, { ' + ($rows -join ", ") + ' })')

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table '_MOD Competitive Benchmark Presets'")
    $lines.Add("`tisHidden")
    $lines.Add("")
    $lines.Add("`tcolumn PresetKey")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [PresetKey]")
    $lines.Add("")
    $lines.Add("`tcolumn PresetName")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [PresetName]")
    $lines.Add("`t`tsortByColumn: PresetSort")
    $lines.Add("")
    $lines.Add("`tcolumn PresetSort")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [PresetSort]")
    $lines.Add("")
    $lines.Add("`tcolumn XAxisLabel")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [XAxisLabel]")
    $lines.Add("")
    $lines.Add("`tcolumn YAxisLabel")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [YAxisLabel]")
    $lines.Add("")
    $lines.Add("`tcolumn SizeLabel")
    $lines.Add("`t`tsummarizeBy: none")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [SizeLabel]")
    $lines.Add("")
    $lines.Add("`tpartition '_MOD Competitive Benchmark Presets' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add(("`t`tsource = {0}" -f $partitionSource))

    return ($lines -join "`r`n")
}

function New-PbiCompetitiveBenchmarkFacadeTemplate {
    param(
        [Parameter(Mandatory = $true)]$PresetBindings,
        [Parameter(Mandatory = $true)]$SelectorMeasureItems
    )

    $defaultPreset = @($PresetBindings)[0]
    $defaultMetric = @($SelectorMeasureItems)[0]
    $defaultPresetOrdinal = [int]$defaultPreset.Ordinal
    $defaultPresetName = ('{0} vs {1}' -f (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$defaultPreset.XBindingKey)), (Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$defaultPreset.YBindingKey)))
    $defaultMetricLabel = Get-PbiBindingTokenLiteral -Property "Label" -BindingKey ([string]$defaultMetric.bindingKey)
    $defaultPresetNameLiteral = ConvertTo-PbiDaxStringLiteral -Value $defaultPresetName
    $defaultMetricLabelLiteral = ConvertTo-PbiDaxStringLiteral -Value $defaultMetricLabel
    $metricSwitchBranches = New-Object System.Collections.Generic.List[string]
    $scatterXBranches = New-Object System.Collections.Generic.List[string]
    $scatterYBranches = New-Object System.Collections.Generic.List[string]
    $scatterSizeBranches = New-Object System.Collections.Generic.List[string]

    for ($index = 0; $index -lt $SelectorMeasureItems.Count; $index++) {
        $item = $SelectorMeasureItems[$index]
        $measureOrdinal = $index + 1
        $metricSwitchBranches.Add(('            "metric_{0}", ''_MOD Competitive Benchmark Inputs''[Competitive Benchmark Selector Metric {1}]' -f $measureOrdinal, $measureOrdinal))
    }

    foreach ($preset in @($PresetBindings)) {
        $presetOrdinal = [int]$preset.Ordinal
        $scatterXBranches.Add(('            {0}, ''_MOD Competitive Benchmark Inputs''[Competitive Benchmark Preset {0} X Input]' -f $presetOrdinal))
        $scatterYBranches.Add(('            {0}, ''_MOD Competitive Benchmark Inputs''[Competitive Benchmark Preset {0} Y Input]' -f $presetOrdinal))
        $scatterSizeBranches.Add(('            {0}, ''_MOD Competitive Benchmark Inputs''[Competitive Benchmark Preset {0} Size Input]' -f $presetOrdinal))
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("table 'MOD Competitive Benchmark'")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Selected Preset Key' =")
    $lines.Add(("`t`tSELECTEDVALUE('_MOD Competitive Benchmark Presets'[PresetKey], {0})" -f $defaultPresetOrdinal))
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Selected Preset Name' =")
    $lines.Add(("`t`tSELECTEDVALUE('_MOD Competitive Benchmark Presets'[PresetName], {0})" -f $defaultPresetNameLiteral))
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Selected Metric Key' =")
    $lines.Add("`t`tSELECTEDVALUE('_MOD Competitive Benchmark Metrics'[MetricKey], ""metric_1"")")
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Selected Metric Label' =")
    $lines.Add(("`t`tSELECTEDVALUE('_MOD Competitive Benchmark Metrics'[MetricLabel], {0})" -f $defaultMetricLabelLiteral))
    $lines.Add("`t`tdisplayFolder: Selection")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Selected Metric Value' =")
    $lines.Add("`t`tSWITCH(")
    $lines.Add("`t`t    [Competitive Benchmark Selected Metric Key],")
    $lines.Add(($metricSwitchBranches -join ",`r`n"))
    $lines.Add("`t`t    BLANK()")
    $lines.Add("`t`t)")
    $lines.Add("`t`tdisplayFolder: Outputs")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Scatter X' =")
    $lines.Add("`t`tSWITCH(")
    $lines.Add("`t`t    [Competitive Benchmark Selected Preset Key],")
    $lines.Add(($scatterXBranches -join ",`r`n"))
    $lines.Add("`t`t    BLANK()")
    $lines.Add("`t`t)")
    $lines.Add("`t`tdisplayFolder: Scatter")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Scatter Y' =")
    $lines.Add("`t`tSWITCH(")
    $lines.Add("`t`t    [Competitive Benchmark Selected Preset Key],")
    $lines.Add(($scatterYBranches -join ",`r`n"))
    $lines.Add("`t`t    BLANK()")
    $lines.Add("`t`t)")
    $lines.Add("`t`tdisplayFolder: Scatter")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Scatter Size' =")
    $lines.Add("`t`tSWITCH(")
    $lines.Add("`t`t    [Competitive Benchmark Selected Preset Key],")
    $lines.Add(($scatterSizeBranches -join ",`r`n"))
    $lines.Add("`t`t    BLANK()")
    $lines.Add("`t`t)")
    $lines.Add("`t`tdisplayFolder: Scatter")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Scatter Size Safe' =")
    $lines.Add("`t`tVAR X = [Competitive Benchmark Scatter Size]")
    $lines.Add("`t`tRETURN IF(ISBLANK(X), -1e99, X)")
    $lines.Add("`t`tdisplayFolder: Scatter")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Scatter X Label' =")
    $lines.Add("`t`tSELECTEDVALUE('_MOD Competitive Benchmark Presets'[XAxisLabel])")
    $lines.Add("`t`tdisplayFolder: Scatter")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Scatter Y Label' =")
    $lines.Add("`t`tSELECTEDVALUE('_MOD Competitive Benchmark Presets'[YAxisLabel])")
    $lines.Add("`t`tdisplayFolder: Scatter")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Scatter Size Label' =")
    $lines.Add("`t`tVAR Label = SELECTEDVALUE('_MOD Competitive Benchmark Presets'[SizeLabel])")
    $lines.Add("`t`tRETURN IF(ISBLANK(Label), BLANK(), ""Size: "" & Label)")
    $lines.Add("`t`tdisplayFolder: Scatter")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Title' =")
    $lines.Add("`t`t[Competitive Benchmark Selected Preset Name] & "" | "" & [Competitive Benchmark Selected Metric Label]")
    $lines.Add("`t`tdisplayFolder: Presentation")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Preset Count' = " + $PresetBindings.Count)
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Diagnostics")
    $lines.Add("")
    $lines.Add("`tmeasure 'Competitive Benchmark Metric Count' = " + $SelectorMeasureItems.Count)
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tdisplayFolder: Diagnostics")
    $lines.Add("")
    $lines.Add("`tcolumn Column")
    $lines.Add("`t`tisHidden")
    $lines.Add("`t`tformatString: 0")
    $lines.Add("`t`tsummarizeBy: sum")
    $lines.Add("`t`tisNameInferred")
    $lines.Add("`t`tsourceColumn: [Column]")
    $lines.Add("")
    $lines.Add("`tpartition 'MOD Competitive Benchmark' = calculated")
    $lines.Add("`t`tmode: import")
    $lines.Add("`t`tsource = Row(""Column"", BLANK())")

    return (($lines -join "`r`n") + "`r`n")
}

function Get-PbiRenderedCompetitiveBenchmarkSemanticAssets {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$ResolvedMappings
    )

    $presetBindings = @(Get-PbiCompetitiveBenchmarkPresetBindings -ResolvedMappings $ResolvedMappings)
    $selectorMeasureItems = @(Get-PbiFlexBindingItems -Manifest $Manifest -ResolvedMappings $ResolvedMappings -CollectionId "selector_measures")

    if ($presetBindings.Count -eq 0) {
        throw "Competitive benchmark rendering requires at least one complete preset binding."
    }

    if ($selectorMeasureItems.Count -eq 0) {
        throw "Competitive benchmark rendering requires at least one selector measure."
    }

    $tableTemplates = [ordered]@{
        "_MOD Competitive Benchmark Inputs"  = (New-PbiCompetitiveBenchmarkInputsTemplate -PresetBindings $presetBindings -SelectorMeasureItems $selectorMeasureItems)
        "_MOD Competitive Benchmark Metrics" = (New-PbiCompetitiveBenchmarkMetricSelectorTemplate -SelectorMeasureItems $selectorMeasureItems)
        "_MOD Competitive Benchmark Presets" = (New-PbiCompetitiveBenchmarkPresetTableTemplate -PresetBindings $presetBindings)
        "MOD Competitive Benchmark"          = (New-PbiCompetitiveBenchmarkFacadeTemplate -PresetBindings $presetBindings -SelectorMeasureItems $selectorMeasureItems)
    }

    $mappings = @()
    foreach ($tableName in @($Manifest.provides.semanticTables)) {
        $destinationPath = Get-PbiTableDefinitionPath -Project $Project -TableName $tableName
        $sourcePath = Join-Path (Join-Path $Module.PackageRoot "semantic") ($tableName + ".tmdl")
        $renderedContent = Convert-PbiTextWithResolvedMappings -Text $tableTemplates[$tableName] -ResolvedMappings $ResolvedMappings
        $mappings += (New-PbiRenderedModuleFileMapping -TableName $tableName -SourcePath $sourcePath -DestinationPath $destinationPath -RelativePath (Get-PbiRelativePath -BasePath $Project.ProjectRoot -Path $destinationPath) -SourceContent $renderedContent)
    }

    return @($mappings)
}

function Get-PbiRenderedModuleSemanticAssets {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Manifest,
        $ResolvedMappings
    )

    if (-not $ResolvedMappings) {
        return @()
    }

    switch (Get-PbiModuleRenderingStrategy -Manifest $Manifest) {
        "flex-flat" { return @(Get-PbiRenderedFlexFlatSemanticAssets -Project $Project -Module $Module -Manifest $Manifest -ResolvedMappings $ResolvedMappings) }
        "flex-pivot" { return @(Get-PbiRenderedFlexPivotSemanticAssets -Project $Project -Module $Module -Manifest $Manifest -ResolvedMappings $ResolvedMappings) }
        "metric-switch" { return @(Get-PbiRenderedMetricSwitchSemanticAssets -Project $Project -Module $Module -Manifest $Manifest -ResolvedMappings $ResolvedMappings) }
        "topn-target-driver" { return @(Get-PbiRenderedTopNDriverSemanticAssets -Project $Project -Module $Module -Manifest $Manifest -ResolvedMappings $ResolvedMappings) }
        "competitive-benchmark" { return @(Get-PbiRenderedCompetitiveBenchmarkSemanticAssets -Project $Project -Module $Module -Manifest $Manifest -ResolvedMappings $ResolvedMappings) }
        default { return @() }
    }
}

function Get-PbiRenderedModuleReportAssets {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Module,
        [Parameter(Mandatory = $true)]$Manifest,
        $ResolvedMappings
    )

    if (-not $ResolvedMappings) {
        return @()
    }

    switch (Get-PbiModuleRenderingStrategy -Manifest $Manifest) {
        "flex-flat" { return @(Get-PbiRenderedFlexFlatReportAssets -Project $Project -Module $Module -Manifest $Manifest -ResolvedMappings $ResolvedMappings) }
        "flex-pivot" { return @(Get-PbiRenderedFlexPivotReportAssets -Project $Project -Module $Module -Manifest $Manifest -ResolvedMappings $ResolvedMappings) }
        default { return @() }
    }
}

Export-ModuleMember -Function Get-PbiModuleRenderingStrategy, Get-PbiRenderedModuleSemanticAssets, Get-PbiRenderedModuleReportAssets
