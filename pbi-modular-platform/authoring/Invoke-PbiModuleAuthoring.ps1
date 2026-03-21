[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("new-authoring-model", "sync-pack-from-authoring")]
    [string]$Command,

    [string]$WorkspaceRoot,
    [string]$Domain,
    [string]$ModuleId,
    [string]$AuthoringPath,
    [ValidateSet("te-folder", "tmdl")]
    [string]$AuthoringFormat,
    [switch]$Force
)

$modulePaths = @(
    "../installer/Modules/Core/Pbi.Runtime.psm1",
    "../installer/Modules/Core/Pbi.Schema.psm1",
    "../installer/Modules/Core/Pbi.Catalog.psm1",
    "../installer/Modules/Core/Pbi.SemanticModel.psm1",
    "Modules/Core/Pbi.Authoring.Shared.psm1",
    "Modules/Providers/Pbi.Authoring.Provider.Tmdl.psm1",
    "Modules/Providers/Pbi.Authoring.Provider.TeFolder.psm1",
    "Modules/Core/Pbi.Authoring.psm1"
)

foreach ($relativeModulePath in $modulePaths) {
    $modulePath = Join-Path $PSScriptRoot $relativeModulePath
    Import-Module $modulePath -Force -DisableNameChecking
}

switch ($Command) {
    "new-authoring-model" {
        if (-not $ModuleId) {
            throw "ModuleId is required for new-authoring-model."
        }

        $commandParams = @{
            WorkspaceRoot = $WorkspaceRoot
            Domain        = $Domain
            ModuleId      = $ModuleId
            AuthoringPath = $AuthoringPath
            Force         = $Force
        }
        if ($AuthoringFormat) {
            $commandParams.AuthoringFormat = $AuthoringFormat
        }

        $result = New-PbiModuleAuthoringModel @commandParams
        Write-Host ("Generated authoring model for module {0}" -f $result.Module.ModuleId)
        Write-Host ("  Authoring format: {0}" -f $result.AuthoringFormat)
        Write-Host ("  Authoring model: {0}" -f $result.AuthoringModelPath)
        Write-Host ("  Managed tables: {0}" -f ($result.ManagedTables -join ", "))
        Write-Host ("  Support tables: {0}" -f ($result.SupportTables -join ", "))
    }
    "sync-pack-from-authoring" {
        if (-not $ModuleId) {
            throw "ModuleId is required for sync-pack-from-authoring."
        }

        $commandParams = @{
            WorkspaceRoot = $WorkspaceRoot
            Domain        = $Domain
            ModuleId      = $ModuleId
            AuthoringPath = $AuthoringPath
        }
        if ($AuthoringFormat) {
            $commandParams.AuthoringFormat = $AuthoringFormat
        }

        $result = Sync-PbiModulePackageFromAuthoringModel @commandParams
        Write-Host ("Synchronized package {0} from authoring model" -f $result.Module.ModuleId)
        Write-Host ("  Authoring format: {0}" -f $result.AuthoringFormat)
        Write-Host ("  Authoring model: {0}" -f $result.AuthoringModelPath)
        Write-Host ("  Files updated: {0}" -f $result.FilesUpdated.Count)
        foreach ($filePath in @($result.FilesUpdated)) {
            Write-Host ("    - {0}" -f $filePath)
        }
    }
}
