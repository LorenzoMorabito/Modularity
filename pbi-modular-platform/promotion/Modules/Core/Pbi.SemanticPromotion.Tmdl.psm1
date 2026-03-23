Set-StrictMode -Version Latest

function Get-PbiTmdlLeadingIndentCount {
    param([Parameter(Mandatory = $true)][string]$Line)

    $count = 0
    foreach ($char in $Line.ToCharArray()) {
        if ($char -eq ' ' -or $char -eq "`t") {
            $count++
            continue
        }

        break
    }

    return $count
}

function Test-PbiTmdlPropertyLine {
    param([Parameter(Mandatory = $true)][string]$Line)

    if ($Line -match "^\s*[A-Za-z_][A-Za-z0-9_-]*\s*:") {
        return $true
    }

    return ($Line -match "^\s*(isHidden|isSimpleMeasure|isSimpleLabel|isNameInferred|isDefault|isPrivate|isUnique|isNullable|showAsVariationsOnly)\s*$")
}

function Get-PbiTmdlObjectDefinitions {
    param([Parameter(Mandatory = $true)][string]$Path)

    $tableName = Get-PbiTmdlTableNameFromFile -Path $Path
    $lines = @(Get-Content -Path $Path)
    $definitions = @()
    $index = 0

    while ($index -lt $lines.Count) {
        $line = $lines[$index]

        if ($line -match "^\s*measure\b") {
            $name = Get-PbiTmdlNameFromLine -Line $line
            $indent = Get-PbiTmdlLeadingIndentCount -Line $line
            $expressionLines = @()
            if ($line -match "=\s*(.*)$") {
                $expressionLines += $matches[1]
            }

            $lookahead = $index + 1
            while ($lookahead -lt $lines.Count) {
                $candidate = $lines[$lookahead]
                if ([string]::IsNullOrWhiteSpace($candidate)) {
                    $expressionLines += ""
                    $lookahead++
                    continue
                }

                $candidateIndent = Get-PbiTmdlLeadingIndentCount -Line $candidate
                if ($candidateIndent -le $indent) {
                    break
                }

                if (Test-PbiTmdlPropertyLine -Line $candidate) {
                    break
                }

                $expressionLines += $candidate.Trim()
                $lookahead++
            }

                $definitions += [PSCustomObject]@{
                    Type           = "measure"
                    Name           = $name
                    TableName      = $tableName
                    FilePath       = $Path
                    StartLine      = $index + 1
                    ExpressionText = ($expressionLines -join [Environment]::NewLine).Trim()
                }

            $index = $lookahead
            continue
        }

        if ($line -match "^\s*column\b") {
            $name = Get-PbiTmdlNameFromLine -Line $line
            $indent = Get-PbiTmdlLeadingIndentCount -Line $line
            $expressionLines = @()
            $hasExpression = $false
            if ($line -match "=\s*(.*)$") {
                $hasExpression = $true
                $expressionLines += $matches[1]
            }

            if ($hasExpression) {
                $lookahead = $index + 1
                while ($lookahead -lt $lines.Count) {
                    $candidate = $lines[$lookahead]
                    if ([string]::IsNullOrWhiteSpace($candidate)) {
                        $expressionLines += ""
                        $lookahead++
                        continue
                    }

                    $candidateIndent = Get-PbiTmdlLeadingIndentCount -Line $candidate
                    if ($candidateIndent -le $indent) {
                        break
                    }

                    if (Test-PbiTmdlPropertyLine -Line $candidate) {
                        break
                    }

                    $expressionLines += $candidate.Trim()
                    $lookahead++
                }

                $definitions += [PSCustomObject]@{
                    Type           = "calculated-column"
                    Name           = $name
                    TableName      = $tableName
                    FilePath       = $Path
                    StartLine      = $index + 1
                    ExpressionText = ($expressionLines -join [Environment]::NewLine).Trim()
                }

                $index = $lookahead
                continue
            }

            $definitions += [PSCustomObject]@{
                Type           = "column"
                Name           = $name
                TableName      = $tableName
                FilePath       = $Path
                StartLine      = $index + 1
                ExpressionText = ""
            }

            $index++
            continue
        }

        if ($line -match "^\s*partition\b") {
            $name = Get-PbiTmdlNameFromLine -Line $line
            $mode = if ($line -match "=\s*([A-Za-z]+)\s*$") { $matches[1] } else { "" }
            $partitionIndent = Get-PbiTmdlLeadingIndentCount -Line $line
            $sourceExpression = ""
            $lookahead = $index + 1

            while ($lookahead -lt $lines.Count) {
                $candidate = $lines[$lookahead]
                if ([string]::IsNullOrWhiteSpace($candidate)) {
                    $lookahead++
                    continue
                }

                $candidateIndent = Get-PbiTmdlLeadingIndentCount -Line $candidate
                if ($candidateIndent -le $partitionIndent) {
                    break
                }

                if ($candidate -match "^\s*source\s*=\s*(.*)$") {
                    $expressionLines = @()
                    if (-not [string]::IsNullOrWhiteSpace($matches[1])) {
                        $expressionLines += $matches[1]
                    }

                    $sourceIndent = Get-PbiTmdlLeadingIndentCount -Line $candidate
                    $lookahead++
                    while ($lookahead -lt $lines.Count) {
                        $sourceLine = $lines[$lookahead]
                        if ([string]::IsNullOrWhiteSpace($sourceLine)) {
                            $expressionLines += ""
                            $lookahead++
                            continue
                        }

                        $sourceLineIndent = Get-PbiTmdlLeadingIndentCount -Line $sourceLine
                        if ($sourceLineIndent -le $sourceIndent) {
                            break
                        }

                        if ((Test-PbiTmdlPropertyLine -Line $sourceLine) -and ($sourceLineIndent -eq ($sourceIndent + 1))) {
                            break
                        }

                        $expressionLines += $sourceLine.Trim()
                        $lookahead++
                    }

                    $sourceExpression = ($expressionLines -join [Environment]::NewLine).Trim()
                    break
                }

                $lookahead++
            }

            $definitions += [PSCustomObject]@{
                Type           = "partition"
                Name           = $name
                TableName      = $tableName
                FilePath       = $Path
                StartLine      = $index + 1
                PartitionMode  = $mode
                ExpressionText = $sourceExpression
            }

            $index++
            continue
        }

        $index++
    }

    return @($definitions)
}

function Get-PbiTmdlTableInventory {
    param([Parameter(Mandatory = $true)][string]$Path)

    $tableName = Get-PbiTmdlTableNameFromFile -Path $Path
    $definitions = @(Get-PbiTmdlObjectDefinitions -Path $Path)
    return [PSCustomObject]@{
        TableName = $tableName
        Columns   = @($definitions | Where-Object { $_.Type -in @("column", "calculated-column") } | ForEach-Object { $_.Name } | Sort-Object -Unique)
        Measures  = @($definitions | Where-Object { $_.Type -eq "measure" } | ForEach-Object { $_.Name } | Sort-Object -Unique)
    }
}

function Get-PbiTmdlInventoryMap {
    param([Parameter(Mandatory = $true)][string[]]$TablePaths)

    $tables = [ordered]@{}
    $measuresByName = @{}

    foreach ($path in $TablePaths) {
        $inventory = Get-PbiTmdlTableInventory -Path $path
        $tables[$inventory.TableName] = $inventory
        foreach ($measureName in @($inventory.Measures)) {
            if (-not $measuresByName.ContainsKey($measureName)) {
                $measuresByName[$measureName] = New-Object System.Collections.Generic.List[string]
            }

            $measuresByName[$measureName].Add($inventory.TableName)
        }
    }

    return [PSCustomObject]@{
        Tables         = $tables
        MeasuresByName = $measuresByName
    }
}

function Get-PbiNormalizedTmdlExpression {
    param([AllowEmptyString()][string]$ExpressionText)

    if ([string]::IsNullOrWhiteSpace($ExpressionText)) {
        return ""
    }

    $normalized = $ExpressionText.Replace("`r", "")
    $normalized = [regex]::Replace($normalized, '```', '')
    $normalized = [regex]::Replace($normalized, "\s+", " ")
    return $normalized.Trim()
}

function New-PbiExternalReference {
    param(
        [Parameter(Mandatory = $true)][string]$TableName,
        [Parameter(Mandatory = $true)][string]$ObjectName,
        [Parameter(Mandatory = $true)][string]$ObjectType,
        [Parameter(Mandatory = $true)][string]$ReferenceType,
        [Parameter(Mandatory = $true)][string]$ReferenceText,
        [Parameter(Mandatory = $true)][string]$SupportStatus,
        [string]$SupportReason = ""
    )

    return [PSCustomObject]@{
        tableName     = $TableName
        objectName    = $ObjectName
        objectType    = $ObjectType
        referenceType = $ReferenceType
        referenceText = $ReferenceText
        supportStatus = $SupportStatus
        supportReason = $SupportReason
        location      = ($TableName + "::" + $ObjectName)
    }
}

function Get-PbiTmdlExternalReferences {
    param(
        [Parameter(Mandatory = $true)][object[]]$Definitions,
        [Parameter(Mandatory = $true)]$ModuleInventory,
        [Parameter(Mandatory = $true)]$TargetInventory
    )

    $results = New-Object System.Collections.Generic.List[object]
    $qualifiedPattern = "'((?:[^']|'')+)'\[(.*?)\]|(?<![A-Za-z0-9_'])\b([A-Za-z_][A-Za-z0-9_ .]*)\[(.*?)\]"
    $tablePattern = "(?i)\b(ALL|ALLSELECTED|REMOVEFILTERS|VALUES|DISTINCT|FILTER|ADDCOLUMNS|SELECTCOLUMNS|COUNTROWS|SUMX|AVERAGEX|MAXX|MINX|TOPN|CALCULATETABLE|KEEPFILTERS|SUMMARIZE|ALLEXCEPT)\s*\(\s*('((?:[^']|'')+)'|([A-Za-z_][A-Za-z0-9_ .()]*))\s*(?=[,\)])"

    foreach ($definition in @($Definitions | Where-Object { -not [string]::IsNullOrWhiteSpace($_.ExpressionText) })) {
        $normalized = Get-PbiNormalizedTmdlExpression -ExpressionText $definition.ExpressionText
        $consumedValues = New-Object System.Collections.Generic.List[string]

        foreach ($match in [regex]::Matches($normalized, $qualifiedPattern)) {
            $tableName = ""
            $objectName = ""
            if ($match.Groups[1].Success) {
                $tableName = $match.Groups[1].Value.Replace("''", "'")
                $objectName = $match.Groups[2].Value
            }
            else {
                $tableName = $match.Groups[3].Value
                $objectName = $match.Groups[4].Value
            }

            $consumedValues.Add($match.Value)
            if ($tableName -like "MOD_BIND_*") {
                continue
            }

            if ($ModuleInventory.Tables.Contains($tableName)) {
                continue
            }

            if ($TargetInventory.Tables.Contains($tableName)) {
                $tableInfo = $TargetInventory.Tables[$tableName]
                if (@($tableInfo.Columns) -contains $objectName) {
                    $results.Add((New-PbiExternalReference -TableName $definition.TableName -ObjectName $definition.Name -ObjectType $definition.Type -ReferenceType "column" -ReferenceText ($tableName + "[" + $objectName + "]") -SupportStatus "supported" -SupportReason "qualified-column-reference"))
                    continue
                }

                if (@($tableInfo.Measures) -contains $objectName) {
                    $results.Add((New-PbiExternalReference -TableName $definition.TableName -ObjectName $definition.Name -ObjectType $definition.Type -ReferenceType "measure" -ReferenceText ($tableName + "[" + $objectName + "]") -SupportStatus "supported" -SupportReason "qualified-measure-reference"))
                    continue
                }
            }

            $results.Add((New-PbiExternalReference -TableName $definition.TableName -ObjectName $definition.Name -ObjectType $definition.Type -ReferenceType "unknown" -ReferenceText ($tableName + "[" + $objectName + "]") -SupportStatus "unsupported" -SupportReason "target-object-not-found"))
        }

        $withoutQualified = $normalized
        foreach ($value in @($consumedValues | Sort-Object Length -Descending)) {
            $escaped = [regex]::Escape($value)
            $withoutQualified = [regex]::Replace($withoutQualified, $escaped, " ", 1)
        }

        foreach ($match in [regex]::Matches($withoutQualified, "(?<![A-Za-z0-9_'])\[(.*?)\]")) {
            $objectName = $match.Groups[1].Value
            if ($objectName -like "MOD_BIND_*") {
                continue
            }

            $isLocalColumn = $false
            if ($ModuleInventory.Tables.Contains($definition.TableName)) {
                $moduleTable = $ModuleInventory.Tables[$definition.TableName]
                $isLocalColumn = (@($moduleTable.Columns) -contains $objectName)
            }

            if ($isLocalColumn) {
                continue
            }

            if ($ModuleInventory.MeasuresByName.ContainsKey($objectName)) {
                continue
            }

            if ($TargetInventory.MeasuresByName.ContainsKey($objectName)) {
                $owners = @($TargetInventory.MeasuresByName[$objectName] | Select-Object -Unique)
                $status = if ($owners.Count -eq 1) { "supported" } else { "manual-review" }
                $reason = if ($owners.Count -eq 1) { "unqualified-measure-reference" } else { "ambiguous-unqualified-measure-reference" }
                $results.Add((New-PbiExternalReference -TableName $definition.TableName -ObjectName $definition.Name -ObjectType $definition.Type -ReferenceType "measure" -ReferenceText ("[" + $objectName + "]") -SupportStatus $status -SupportReason $reason))
                continue
            }

            $results.Add((New-PbiExternalReference -TableName $definition.TableName -ObjectName $definition.Name -ObjectType $definition.Type -ReferenceType "unknown" -ReferenceText ("[" + $objectName + "]") -SupportStatus "unsupported" -SupportReason "unresolved-unqualified-reference"))
        }

        foreach ($match in [regex]::Matches($withoutQualified, $tablePattern)) {
            $tableName = if ($match.Groups[3].Success) {
                $match.Groups[3].Value.Replace("''", "'")
            }
            else {
                $match.Groups[4].Value.Trim()
            }

            if ([string]::IsNullOrWhiteSpace($tableName) -or ($tableName -like "MOD_BIND_*")) {
                continue
            }

            if ($ModuleInventory.Tables.Contains($tableName)) {
                continue
            }

            if ($TargetInventory.Tables.Contains($tableName)) {
                $results.Add((New-PbiExternalReference -TableName $definition.TableName -ObjectName $definition.Name -ObjectType $definition.Type -ReferenceType "table" -ReferenceText $tableName -SupportStatus "supported" -SupportReason "table-reference"))
                continue
            }

            $results.Add((New-PbiExternalReference -TableName $definition.TableName -ObjectName $definition.Name -ObjectType $definition.Type -ReferenceType "table" -ReferenceText $tableName -SupportStatus "unsupported" -SupportReason "unresolved-table-reference"))
        }
    }

    return @(
        $results |
            Sort-Object tableName, objectName, referenceType, referenceText -Unique
    )
}

function ConvertTo-PbiBindingTokenSuffix {
    param([Parameter(Mandatory = $true)][string]$Text)

    $normalized = $Text.ToUpperInvariant()
    $normalized = [regex]::Replace($normalized, "[^A-Z0-9]+", "_")
    $normalized = [regex]::Replace($normalized, "_{2,}", "_")
    return $normalized.Trim("_")
}

function Test-PbiInputTableName {
    param([Parameter(Mandatory = $true)][string]$TableName)

    return ($TableName -match "^_MOD .*\bInputs?\b")
}

function Get-PbiSimpleBindingCandidates {
    param(
        [Parameter(Mandatory = $true)][object[]]$Definitions,
        [Parameter(Mandatory = $true)]$TargetInventory
    )

    $candidates = New-Object System.Collections.Generic.List[object]

    foreach ($definition in @($Definitions | Where-Object { -not [string]::IsNullOrWhiteSpace($_.ExpressionText) })) {
        if (-not (Test-PbiInputTableName -TableName $definition.TableName)) {
            continue
        }

        $normalized = Get-PbiNormalizedTmdlExpression -ExpressionText $definition.ExpressionText

        if ($normalized -match "^\[(.+?)\]$") {
            $measureName = $matches[1]
            if (-not $TargetInventory.MeasuresByName.ContainsKey($measureName)) {
                continue
            }

            $owners = @($TargetInventory.MeasuresByName[$measureName] | Select-Object -Unique)
            if ($owners.Count -ne 1) {
                continue
            }

            $token = "MOD_BIND_" + (ConvertTo-PbiBindingTokenSuffix -Text $measureName)
            $candidates.Add([PSCustomObject]@{
                tableName       = $definition.TableName
                objectName      = $definition.Name
                objectType      = $definition.Type
                kind            = "measure"
                bindingKey      = $token
                targetReference = $measureName
                replacementText = "[" + $token + "]"
                originalText    = "[" + $measureName + "]"
                roleId          = ($token.ToLowerInvariant() -replace "^mod_bind_", "")
                label           = $measureName
                description     = ("Bind target measure for " + $definition.Name + ".")
                defaultValue    = $measureName
            })
            continue
        }

        if ($normalized -match "^(?:SELECTEDVALUE|VALUES|DISTINCT)\(\s*(?:'((?:[^']|'')+)'|([A-Za-z_][A-Za-z0-9_ .()]*))\[(.*?)\](?:\s*,.*)?\)$") {
            $tableName = if ($matches[1]) { $matches[1].Replace("''", "'") } else { $matches[2].Trim() }
            $columnName = $matches[3]
            if (-not $TargetInventory.Tables.Contains($tableName)) {
                continue
            }

            $suffix = ConvertTo-PbiBindingTokenSuffix -Text ($tableName + "_" + $columnName)
            $tableToken = "MOD_BIND_" + $suffix
            $originalRef = $tableName + "[" + $columnName + "]"
            $candidates.Add([PSCustomObject]@{
                tableName       = $definition.TableName
                objectName      = $definition.Name
                objectType      = $definition.Type
                kind            = "column"
                bindingKey      = ($tableToken + "[Value]")
                bindingTable    = $tableToken
                targetReference = $originalRef
                replacementText = ($tableToken + "[Value]")
                originalText    = $originalRef
                roleId          = ("column_" + $suffix.ToLowerInvariant())
                label           = $columnName
                description     = ("Bind target column for " + $definition.Name + ".")
                defaultValue    = $originalRef
            })
        }
    }

    return @(
        $candidates |
            Sort-Object kind, bindingKey, tableName, objectName -Unique
    )
}

Export-ModuleMember -Function `
    Get-PbiTmdlLeadingIndentCount, `
    Test-PbiTmdlPropertyLine, `
    Get-PbiTmdlObjectDefinitions, `
    Get-PbiTmdlTableInventory, `
    Get-PbiTmdlInventoryMap, `
    Get-PbiNormalizedTmdlExpression, `
    Get-PbiTmdlExternalReferences, `
    ConvertTo-PbiBindingTokenSuffix, `
    Test-PbiInputTableName, `
    Get-PbiSimpleBindingCandidates
