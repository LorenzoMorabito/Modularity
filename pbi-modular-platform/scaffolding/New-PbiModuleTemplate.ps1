[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [Parameter(Mandatory = $true)][string]$Domain,
    [Parameter(Mandatory = $true)][string]$ModuleId,
    [string]$DisplayName,
    [ValidateSet("report-only", "semantic")]
    [string]$Type = "semantic",
    [ValidateSet("report-only", "semantic-light", "semantic-heavy")]
    [string]$Classification,
    [string]$OutputRoot,
    [switch]$IncludeReportPage,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowNull()][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, [string]$Content, $encoding)
}

function New-ReadmeTemplateContent {
    param(
        [Parameter(Mandatory = $true)][string]$DisplayName
    )

    return (@(
        ("# {0}" -f $DisplayName),
        "",
        "<!-- PBI_PACKAGE_README_STANDARD_V1 -->",
        "",
        "## Cos'e questo modulo",
        "",
        "[TODO] Spiega in 3-5 righe quale problema risolve il modulo e quale componente installa nel modello Power BI.",
        "",
        "## Cosa fa",
        "",
        "[TODO] Descrivi quali logiche, KPI, selettori o strutture analitiche abilita il modulo.",
        "",
        "## Cosa fornisce",
        "",
        "[TODO] Elenca in linguaggio semplice cosa mette a disposizione nel modello o nel report.",
        "",
        "## Quando utilizzarlo",
        "",
        "[TODO] Descrivi i casi d'uso tipici e quando questo modulo e la scelta giusta.",
        "",
        "## Requisiti",
        "",
        "[TODO] Indica dimensioni, misure, prerequisiti o condizioni minime richieste dal consumer.",
        "",
        "## Quando non utilizzarlo",
        "",
        "[TODO] Descrivi i casi in cui il modulo non e adatto o sarebbe eccessivo.",
        "",
        "## Installazione rapida",
        "",
        '1. esegui `suggest-bindings` e salva il profilo di binding',
        '2. esegui `validate`',
        '3. esegui `install`',
        '4. esegui `test`',
        "",
        'Per dettagli tecnici, parametri CLI, asset installati e limiti usare anche `PACKAGE.md`.'
    ) -join "`r`n")
}

function New-PackageTemplateContent {
    param(
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [Parameter(Mandatory = $true)][string]$Domain,
        [Parameter(Mandatory = $true)][string]$Type,
        [Parameter(Mandatory = $true)][string]$Classification,
        [Parameter(Mandatory = $true)][string]$SemanticImpact,
        [bool]$HasReportPage
    )

    $providedObjectsLine = if ($HasReportPage) {
        "- [TODO] Elenca tabelle semantic, pagina report e altri asset installati."
    }
    else {
        "- [TODO] Elenca tabelle semantic e altri asset installati."
    }

    $assetLines = @(
        '- `manifest.json`: contratto del modulo, binding, output dichiarati e metadati installativi.',
        '- `README.md`: descrizione business e guida rapida del modulo.',
        '- `PACKAGE.md`: scheda installativa operativa del package.'
    )

    if ($Type -eq "semantic") {
        $assetLines += '- `semantic/`: asset semantic sorgente che il framework materializza nel consumer.'
    }

    if ($HasReportPage) {
        $assetLines += '- `report/`: asset report sorgente che il framework materializza nel consumer.'
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(("# {0}" -f $DisplayName))
    $lines.Add("")
    $lines.Add("<!-- PBI_PACKAGE_SHEET_STANDARD_V1 -->")
    $lines.Add("")
    $lines.Add("## Identita")
    $lines.Add(('- Modulo: `{0}`' -f $ModuleId))
    $lines.Add(('- Dominio: `{0}`' -f $Domain))
    $lines.Add('- Versione: `0.1.0`')
    $lines.Add(('- Tipo: `{0}`' -f $Type))
    $lines.Add(('- Classification: `{0}`' -f $Classification))
    $lines.Add(('- Semantic impact: `{0}`' -f $SemanticImpact))
    $lines.Add('- Stato: `prototype`')
    $lines.Add('- Compatibilita consumer dichiarata: `[TODO] Definire e riportare anche in catalog/modules.json.`')
    $lines.Add('- Descrizione: `[TODO] Sintetizza in una frase il valore del modulo.`')
    $lines.Add("")
    $lines.Add("## Caratteristiche")
    $lines.Add("- [TODO] Descrivi le caratteristiche chiave del modulo.")
    $lines.Add("- [TODO] Indica se installa solo asset semantic, solo report o entrambi.")
    $lines.Add("")
    $lines.Add("## Cosa installa")
    $lines.Add($providedObjectsLine)
    $lines.Add("- [TODO] Indica quale tabella o pagina rappresenta il punto di ingresso principale.")
    $lines.Add("")
    $lines.Add("## Prerequisiti dichiarati")
    $lines.Add('- Moduli dipendenti: `nessuno`')
    $lines.Add('- Capability richieste: `nessuna`')
    $lines.Add('- Core measures richieste: `[TODO] Elencare oppure scrivere nessuna dichiarata.`')
    $lines.Add('- Core columns richieste: `[TODO] Elencare oppure scrivere nessuna dichiarata.`')
    $lines.Add("")
    $lines.Add("## Parametri di binding")
    $lines.Add("")
    $lines.Add("[TODO] Documenta ogni binding richiesto con significato funzionale, tipo e suggerimenti.")
    $lines.Add("")
    $lines.Add("## Cosa non fa")
    $lines.Add("- [TODO] Elenca i limiti dichiarati del modulo.")
    $lines.Add("")
    $lines.Add("## Installazione corretta")
    $lines.Add('- Parametri CLI base: `-ProjectPath`, `-Domain`, `-ModuleId`')
    $lines.Add('- Parametri CLI consigliati per il binding: `-InteractiveUi`, `-SaveBindingProfileAs`, `-BindingProfileId`, `-MappingFile`')
    $lines.Add("")
    $lines.Add('```powershell')
    $lines.Add('pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `')
    $lines.Add('  -Command suggest-bindings `')
    $lines.Add('  -WorkspaceRoot <WORKSPACE_ROOT> `')
    $lines.Add('  -ProjectPath <PROJECT_PATH> `')
    $lines.Add(('  -Domain {0} `' -f $Domain))
    $lines.Add(('  -ModuleId {0} `' -f $ModuleId))
    $lines.Add('  -InteractiveUi `')
    $lines.Add('  -SaveBindingProfileAs <PROFILE_ID>')
    $lines.Add('```')
    $lines.Add("")
    $lines.Add('```powershell')
    $lines.Add('pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `')
    $lines.Add('  -Command validate `')
    $lines.Add('  -WorkspaceRoot <WORKSPACE_ROOT> `')
    $lines.Add('  -ProjectPath <PROJECT_PATH> `')
    $lines.Add(('  -Domain {0} `' -f $Domain))
    $lines.Add(('  -ModuleId {0} `' -f $ModuleId))
    $lines.Add('  -BindingProfileId <PROFILE_ID>')
    $lines.Add('```')
    $lines.Add("")
    $lines.Add('```powershell')
    $lines.Add('pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `')
    $lines.Add('  -Command install `')
    $lines.Add('  -WorkspaceRoot <WORKSPACE_ROOT> `')
    $lines.Add('  -ProjectPath <PROJECT_PATH> `')
    $lines.Add(('  -Domain {0} `' -f $Domain))
    $lines.Add(('  -ModuleId {0} `' -f $ModuleId))
    $lines.Add('  -BindingProfileId <PROFILE_ID>')
    $lines.Add('```')
    $lines.Add("")
    $lines.Add('```powershell')
    $lines.Add('pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `')
    $lines.Add('  -Command test `')
    $lines.Add('  -WorkspaceRoot <WORKSPACE_ROOT> `')
    $lines.Add('  -ProjectPath <PROJECT_PATH>')
    $lines.Add('```')
    $lines.Add("")
    $lines.Add("## Uso consigliato")
    $lines.Add("- [TODO] Indica come partire bene, cosa verificare dopo l'installazione e come usare il modulo senza errori comuni.")
    $lines.Add("")
    $lines.Add("## File del package")
    foreach ($assetLine in $assetLines) {
        $lines.Add($assetLine)
    }

    return ($lines -join "`r`n")
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$platformRoot = Split-Path -Parent $scriptRoot
$runtimeModulePath = Join-Path $platformRoot "installer/Modules/Core/Pbi.Runtime.psm1"
Import-Module $runtimeModulePath -Force -DisableNameChecking

$resolvedWorkspaceRoot = Get-PbiInstallerWorkspaceRoot -WorkspaceRoot $WorkspaceRoot -ScriptRoot $platformRoot
$modularityRoot = if (Test-Path (Join-Path $resolvedWorkspaceRoot "modularity")) { Join-Path $resolvedWorkspaceRoot "modularity" } else { $resolvedWorkspaceRoot }
$domainRoot = Join-Path $modularityRoot ("pbi-" + $Domain + "-domain")

if (-not (Test-Path $domainRoot)) {
    throw "Domain root '$domainRoot' does not exist."
}

if (-not $DisplayName) {
    $DisplayName = (($ModuleId -split "_") | ForEach-Object {
        if ($_.Length -gt 0) {
            $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1)
        }
    }) -join " "
}

if (-not $Classification) {
    $Classification = if ($Type -eq "report-only") { "report-only" } else { "semantic-light" }
}

if (-not $OutputRoot) {
    $OutputRoot = Join-Path $domainRoot ("packages/" + $ModuleId)
}

if ((Test-Path $OutputRoot) -and -not $Force) {
    throw "Target module path '$OutputRoot' already exists. Use -Force to overwrite."
}

if (Test-Path $OutputRoot) {
    Remove-Item -Path $OutputRoot -Recurse -Force
}

$semanticImpact = if ($Type -eq "report-only") { "none" } else { "additive" }
$semanticTables = if ($Type -eq "semantic") { @("MOD " + $DisplayName + " Placeholder") } else { @() }
$reportPage = if ($Type -eq "report-only" -or $IncludeReportPage) {
    [ordered]@{
        name        = ($ModuleId + "_page")
        displayName = $DisplayName
    }
}
else {
    $null
}

$manifest = [ordered]@{
    moduleId       = $ModuleId
    version        = "0.1.0"
    domain         = $Domain
    type           = $Type
    classification = $Classification
    dependencies   = [ordered]@{
        modules      = @()
        capabilities = @()
    }
    semanticImpact = $semanticImpact
    status         = "prototype"
    description    = ("TODO: describe module '{0}'." -f $DisplayName)
    requires       = [ordered]@{
        coreMeasures = @()
        coreColumns  = @()
    }
    semanticUx     = if ($Type -eq "semantic") {
        [ordered]@{
            primaryTable = $semanticTables[0]
            hiddenTables = @()
        }
    }
    else {
        $null
    }
    provides       = [ordered]@{
        semanticTables = @($semanticTables)
    }
}

if ($reportPage) {
    $manifest.provides["reportPage"] = $reportPage
}

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
Write-Utf8NoBom -Path (Join-Path $OutputRoot "manifest.json") -Content (ConvertTo-PbiJsonText -InputObject $manifest)
Write-Utf8NoBom -Path (Join-Path $OutputRoot "README.md") -Content (New-ReadmeTemplateContent -DisplayName $DisplayName)
Write-Utf8NoBom -Path (Join-Path $OutputRoot "PACKAGE.md") -Content (New-PackageTemplateContent -DisplayName $DisplayName -ModuleId $ModuleId -Domain $Domain -Type $Type -Classification $Classification -SemanticImpact $semanticImpact -HasReportPage ([bool]$reportPage))

if ($Type -eq "semantic") {
    $semanticRoot = Join-Path $OutputRoot "semantic"
    New-Item -ItemType Directory -Path $semanticRoot -Force | Out-Null
    $tableName = $semanticTables[0]
    $tmdl = @(
        ("table '{0}'" -f $tableName),
        "",
        "    column Placeholder",
        "        dataType: string",
        "",
        ("    partition '{0}' = calculated" -f $tableName),
        "        mode: import",
        "        source = DATATABLE(""Placeholder"", STRING, {{ { ""TODO"" } }})"
    ) -join "`r`n"
    Write-Utf8NoBom -Path (Join-Path $semanticRoot ($tableName + ".tmdl")) -Content $tmdl
}

if ($reportPage) {
    $reportRoot = Join-Path $OutputRoot "report"
    New-Item -ItemType Directory -Path $reportRoot -Force | Out-Null
    Write-Utf8NoBom -Path (Join-Path $reportRoot "page.json") -Content "{`"name`":`"$($reportPage.name)`",`"displayName`":`"$($reportPage.displayName)`"}"
}

Write-Host ("Generated module scaffold at {0}" -f $OutputRoot)
