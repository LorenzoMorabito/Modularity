Set-StrictMode -Version Latest

function Get-PbiAutoDateArtifactIndentCount {
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

function Get-PbiAutoDateArtifactNormalizedContent {
    param([AllowEmptyCollection()][string[]]$Lines = @())

    if (@($Lines).Count -eq 0) {
        return ""
    }

    $normalized = (($Lines -join [Environment]::NewLine).Replace("`r", "")) -replace "`r`n", "`n"
    $normalized = [regex]::Replace($normalized, "(\n\s*){3,}", "`n`n")
    return $normalized.TrimEnd()
}

function Test-PbiAutoDateArtifactTableName {
    param([AllowEmptyString()][string]$TableName)

    if ([string]::IsNullOrWhiteSpace($TableName)) {
        return $false
    }

    return ($TableName -match "^(LocalDateTable|DateTableTemplate)_[0-9a-fA-F-]+$")
}

function Get-PbiAutoDateArtifactTableNames {
    param([AllowEmptyCollection()][string[]]$TableNames = @())

    return @(
        @($TableNames) |
            Where-Object { Test-PbiAutoDateArtifactTableName -TableName ([string]$_) } |
            Sort-Object -Unique
    )
}

function Get-PbiNormalizedTableContentRemovingAutoDateVariations {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path -PathType Leaf)) {
        return ""
    }

    $lines = @(Get-Content -Path $Path)
    $keptLines = New-Object System.Collections.Generic.List[string]
    $index = 0

    while ($index -lt $lines.Count) {
        $line = $lines[$index]
        if ($line -match "^\s*variation\b") {
            $variationIndent = Get-PbiAutoDateArtifactIndentCount -Line $line
            $blockLines = New-Object System.Collections.Generic.List[string]
            $blockLines.Add($line)
            $lookahead = $index + 1

            while ($lookahead -lt $lines.Count) {
                $candidate = $lines[$lookahead]
                if ([string]::IsNullOrWhiteSpace($candidate)) {
                    $blockLines.Add($candidate)
                    $lookahead++
                    continue
                }

                $candidateIndent = Get-PbiAutoDateArtifactIndentCount -Line $candidate
                if ($candidateIndent -le $variationIndent) {
                    break
                }

                $blockLines.Add($candidate)
                $lookahead++
            }

            $blockText = $blockLines.ToArray() -join [Environment]::NewLine
            if ($blockText -match "defaultHierarchy:\s+('?((LocalDateTable|DateTableTemplate)_[0-9a-fA-F-]+)'?)\.") {
                $index = $lookahead
                continue
            }
        }

        $keptLines.Add($line)
        $index++
    }

    return (Get-PbiAutoDateArtifactNormalizedContent -Lines $keptLines.ToArray())
}

function Get-PbiNormalizedRelationshipsContentRemovingAutoDateArtifacts {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path -PathType Leaf)) {
        return ""
    }

    $lines = @(Get-Content -Path $Path)
    if ($lines.Count -eq 0) {
        return ""
    }

    $blocks = New-Object System.Collections.Generic.List[object]
    $currentBlock = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        if (($line -match "^\s*relationship\b") -and ($currentBlock.Count -gt 0)) {
            $blocks.Add([PSCustomObject]@{ Lines = $currentBlock.ToArray() })
            $currentBlock = New-Object System.Collections.Generic.List[string]
        }

        $currentBlock.Add($line)
    }

    if ($currentBlock.Count -gt 0) {
        $blocks.Add([PSCustomObject]@{ Lines = $currentBlock.ToArray() })
    }

    $keptLines = New-Object System.Collections.Generic.List[string]
    foreach ($block in $blocks.ToArray()) {
        $blockText = @($block.Lines) -join [Environment]::NewLine
        if ($blockText -match "(LocalDateTable|DateTableTemplate)_[0-9a-fA-F-]+") {
            continue
        }

        if ($keptLines.Count -gt 0) {
            $keptLines.Add("")
        }

        foreach ($line in @($block.Lines)) {
            $keptLines.Add($line)
        }
    }

    return (Get-PbiAutoDateArtifactNormalizedContent -Lines $keptLines.ToArray())
}

function Test-PbiSemanticPromotionAllowedRelationshipsDelta {
    param(
        [Parameter(Mandatory = $true)]$BaselineEntry,
        [Parameter(Mandatory = $true)][string]$CurrentPath
    )

    $currentNormalizedSha256 = Get-PbiStringSha256 -Text (Get-PbiNormalizedRelationshipsContentRemovingAutoDateArtifacts -Path $CurrentPath)

    if ($BaselineEntry.PSObject.Properties["normalizedAutoDateSha256"]) {
        return ($currentNormalizedSha256 -eq [string]$BaselineEntry.normalizedAutoDateSha256)
    }

    return ($currentNormalizedSha256 -eq [string]$BaselineEntry.sha256)
}

function Test-PbiSemanticPromotionAllowedTableDelta {
    param(
        [Parameter(Mandatory = $true)]$BaselineEntry,
        [Parameter(Mandatory = $true)][string]$CurrentPath
    )

    $currentNormalizedSha256 = Get-PbiStringSha256 -Text (Get-PbiNormalizedTableContentRemovingAutoDateVariations -Path $CurrentPath)

    if ($BaselineEntry.PSObject.Properties["normalizedAutoDateSha256"]) {
        return ($currentNormalizedSha256 -eq [string]$BaselineEntry.normalizedAutoDateSha256)
    }

    return ($currentNormalizedSha256 -eq [string]$BaselineEntry.sha256)
}

Export-ModuleMember -Function `
    Test-PbiAutoDateArtifactTableName, `
    Get-PbiAutoDateArtifactTableNames, `
    Get-PbiNormalizedTableContentRemovingAutoDateVariations, `
    Get-PbiNormalizedRelationshipsContentRemovingAutoDateArtifacts, `
    Test-PbiSemanticPromotionAllowedRelationshipsDelta, `
    Test-PbiSemanticPromotionAllowedTableDelta
