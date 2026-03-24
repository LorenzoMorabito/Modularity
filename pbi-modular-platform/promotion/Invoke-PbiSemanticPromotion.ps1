[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("new-promotion-baseline", "promote-semantic-module")]
    [string]$Command,

    [string]$WorkspaceRoot,
    [string]$ProjectPath,
    [string]$Domain,
    [string]$ModuleId,
    [string]$OutputRoot,
    [string]$Version = "0.1.0",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$modulePaths = @(
    "../installer/Modules/Core/Pbi.Runtime.psm1",
    "../installer/Modules/Core/Pbi.Schema.psm1",
    "../installer/Modules/Core/Pbi.Project.psm1",
    "Modules/Core/Pbi.SemanticPromotion.Shared.psm1",
    "Modules/Core/Pbi.SemanticPromotion.AutoDateArtifacts.psm1",
    "Modules/Core/Pbi.SemanticPromotion.Tmdl.psm1",
    "Modules/Core/Pbi.SemanticPromotion.psm1"
)

foreach ($relativeModulePath in $modulePaths) {
    $modulePath = Join-Path $PSScriptRoot $relativeModulePath
    Import-Module $modulePath -Force -DisableNameChecking
}

switch ($Command) {
    "new-promotion-baseline" {
        if (-not $ProjectPath) {
            throw "ProjectPath is required for new-promotion-baseline."
        }

        if (-not $ModuleId) {
            throw "ModuleId is required for new-promotion-baseline."
        }

        $result = New-PbiSemanticPromotionBaseline `
            -WorkspaceRoot $WorkspaceRoot `
            -ProjectPath $ProjectPath `
            -ModuleId $ModuleId

        Write-Host ("Created promotion baseline for module {0}" -f $result.ModuleId)
        Write-Host ("  Baseline path: {0}" -f $result.BaselinePath)
        Write-Host ("  Workbench mode: {0}" -f $result.WorkbenchMode)
        Write-Host ("  Baseline tables: {0}" -f $result.TableCount)
    }
    "promote-semantic-module" {
        if (-not $ProjectPath) {
            throw "ProjectPath is required for promote-semantic-module."
        }

        if (-not $ModuleId) {
            throw "ModuleId is required for promote-semantic-module."
        }

        if (-not $Domain) {
            throw "Domain is required for promote-semantic-module."
        }

        $commandParams = @{
            WorkspaceRoot = $WorkspaceRoot
            ProjectPath   = $ProjectPath
            Domain        = $Domain
            ModuleId      = $ModuleId
            Version       = $Version
            Force         = $Force
        }

        if ($OutputRoot) {
            $commandParams.OutputRoot = $OutputRoot
        }

        $result = Invoke-PbiSemanticModulePromotion @commandParams
        Write-Host ("Promoted semantic module {0}" -f $result.ModuleId)
        Write-Host ("  Package root: {0}" -f $result.PackageRoot)
        Write-Host ("  Semantic tables: {0}" -f ($result.Manifest.provides.semanticTables -join ", "))
        Write-Host ("  External bindings: {0}" -f $result.BindingSummary.Count)
        Write-Host ("  Report (json): {0}" -f $result.Report.JsonPath)
        Write-Host ("  Report (md): {0}" -f $result.Report.MarkdownPath)
    }
}
