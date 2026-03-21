Set-StrictMode -Version Latest

function Resolve-PbiModuleAuthoringTarget {
    param(
        [Parameter(Mandatory = $true)]$Module,
        [string]$AuthoringPath,
        [ValidateSet("te-folder", "tmdl")]
        [string]$AuthoringFormat,
        [switch]$ForCreation
    )

    if ($AuthoringPath) {
        $resolvedPath = [System.IO.Path]::GetFullPath($AuthoringPath)
        $resolvedFormat = if ($AuthoringFormat) {
            $AuthoringFormat
        }
        else {
            Resolve-PbiModuleAuthoringFormatFromPath -AuthoringPath $resolvedPath
        }

        return [PSCustomObject]@{
            AuthoringPath   = $resolvedPath
            AuthoringFormat = $resolvedFormat
        }
    }

    if ($ForCreation) {
        $resolvedFormat = if ($AuthoringFormat) { $AuthoringFormat } else { "te-folder" }
        return [PSCustomObject]@{
            AuthoringPath   = (Get-PbiModuleDefaultAuthoringPath -Module $Module -AuthoringFormat $resolvedFormat)
            AuthoringFormat = $resolvedFormat
        }
    }

    if ($AuthoringFormat) {
        return [PSCustomObject]@{
            AuthoringPath   = (Get-PbiModuleDefaultAuthoringPath -Module $Module -AuthoringFormat $AuthoringFormat)
            AuthoringFormat = $AuthoringFormat
        }
    }

    foreach ($candidateFormat in @("te-folder", "tmdl")) {
        $candidatePath = Get-PbiModuleDefaultAuthoringPath -Module $Module -AuthoringFormat $candidateFormat
        $candidateMetadataPath = Get-PbiModuleAuthoringMetadataPath -AuthoringModelPath $candidatePath
        if (Test-Path $candidateMetadataPath) {
            return [PSCustomObject]@{
                AuthoringPath   = $candidatePath
                AuthoringFormat = (Resolve-PbiModuleAuthoringFormatFromPath -AuthoringPath $candidatePath)
            }
        }
    }

    return [PSCustomObject]@{
        AuthoringPath   = (Get-PbiModuleDefaultAuthoringPath -Module $Module -AuthoringFormat "te-folder")
        AuthoringFormat = "te-folder"
    }
}

function New-PbiModuleAuthoringModel {
    param(
        [string]$WorkspaceRoot,
        [string]$Domain,
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [string]$AuthoringPath,
        [ValidateSet("te-folder", "tmdl")]
        [string]$AuthoringFormat,
        [switch]$Force
    )

    $resolvedWorkspaceRoot = Get-PbiInstallerWorkspaceRoot -WorkspaceRoot $WorkspaceRoot -ScriptRoot $PSScriptRoot
    $module = Get-PbiSingleModule -WorkspaceRoot $resolvedWorkspaceRoot -Domain $Domain -ModuleId $ModuleId
    $summary = Get-PbiModuleAuthoringManifestSummary -Module $module
    $targetParams = @{
        Module        = $module
        AuthoringPath = $AuthoringPath
        ForCreation   = $true
    }
    if ($AuthoringFormat) {
        $targetParams.AuthoringFormat = $AuthoringFormat
    }
    $target = Resolve-PbiModuleAuthoringTarget @targetParams

    switch ($target.AuthoringFormat) {
        "tmdl" {
            return (New-PbiTmdlAuthoringModel `
                    -WorkspaceRoot $resolvedWorkspaceRoot `
                    -Module $module `
                    -Summary $summary `
                    -AuthoringPath $target.AuthoringPath `
                    -Force:$Force)
        }
        "te-folder" {
            return (New-PbiTeFolderAuthoringModel `
                    -WorkspaceRoot $resolvedWorkspaceRoot `
                    -Module $module `
                    -Summary $summary `
                    -AuthoringPath $target.AuthoringPath `
                    -Force:$Force)
        }
    }
}

function Sync-PbiModulePackageFromAuthoringModel {
    param(
        [string]$WorkspaceRoot,
        [string]$Domain,
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [string]$AuthoringPath,
        [ValidateSet("te-folder", "tmdl")]
        [string]$AuthoringFormat
    )

    $resolvedWorkspaceRoot = Get-PbiInstallerWorkspaceRoot -WorkspaceRoot $WorkspaceRoot -ScriptRoot $PSScriptRoot
    $module = Get-PbiSingleModule -WorkspaceRoot $resolvedWorkspaceRoot -Domain $Domain -ModuleId $ModuleId
    $summary = Get-PbiModuleAuthoringManifestSummary -Module $module
    $targetParams = @{
        Module        = $module
        AuthoringPath = $AuthoringPath
    }
    if ($AuthoringFormat) {
        $targetParams.AuthoringFormat = $AuthoringFormat
    }
    $target = Resolve-PbiModuleAuthoringTarget @targetParams

    switch ($target.AuthoringFormat) {
        "tmdl" {
            return (Sync-PbiPackageFromTmdlAuthoringModel `
                    -Module $module `
                    -Summary $summary `
                    -AuthoringPath $target.AuthoringPath)
        }
        "te-folder" {
            return (Sync-PbiPackageFromTeFolderAuthoringModel `
                    -Module $module `
                    -Summary $summary `
                    -AuthoringPath $target.AuthoringPath)
        }
    }
}

Export-ModuleMember -Function `
    Get-PbiModuleDefaultAuthoringPath, `
    Get-PbiModuleDefaultAuthoringModelPath, `
    Get-PbiModuleAuthoringMetadataPath, `
    New-PbiModuleAuthoringModel, `
    Sync-PbiModulePackageFromAuthoringModel
