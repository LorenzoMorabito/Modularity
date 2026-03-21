[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("new-authoring-model", "sync-pack-from-authoring")]
    [string]$Command,

    [string]$WorkspaceRoot,
    [string]$Domain,
    [string]$ModuleId,
    [string]$AuthoringPath,
    [switch]$Force
)

$modulePaths = @(
    "../installer/Modules/Core/Pbi.Runtime.psm1",
    "../installer/Modules/Core/Pbi.Schema.psm1",
    "../installer/Modules/Core/Pbi.Catalog.psm1",
    "../installer/Modules/Core/Pbi.SemanticModel.psm1",
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

        $result = New-PbiModuleAuthoringModel -WorkspaceRoot $WorkspaceRoot -Domain $Domain -ModuleId $ModuleId -AuthoringPath $AuthoringPath -Force:$Force
        Write-Host ("Generated authoring model for module {0}" -f $result.Module.ModuleId)
        Write-Host ("  Authoring model: {0}" -f $result.AuthoringModelPath)
        Write-Host ("  Managed tables: {0}" -f ($result.ManagedTables -join ", "))
        Write-Host ("  Support tables: {0}" -f ($result.SupportTables -join ", "))
    }
    "sync-pack-from-authoring" {
        if (-not $ModuleId) {
            throw "ModuleId is required for sync-pack-from-authoring."
        }

        $result = Sync-PbiModulePackageFromAuthoringModel -WorkspaceRoot $WorkspaceRoot -Domain $Domain -ModuleId $ModuleId -AuthoringPath $AuthoringPath
        Write-Host ("Synchronized package {0} from authoring model" -f $result.Module.ModuleId)
        Write-Host ("  Authoring model: {0}" -f $result.AuthoringModelPath)
        Write-Host ("  Files updated: {0}" -f $result.FilesUpdated.Count)
        foreach ($filePath in @($result.FilesUpdated)) {
            Write-Host ("    - {0}" -f $filePath)
        }
    }
}
