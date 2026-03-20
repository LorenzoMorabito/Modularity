param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowNull()]
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, [string]$Content, $encoding)
}

function Test-ObjectProperty {
    param(
        [AllowNull()]$InputObject,
        [Parameter(Mandatory = $true)][string]$Name
    )

    return ($null -ne $InputObject) -and ($null -ne $InputObject.PSObject.Properties[$Name])
}

function Get-ObjectPropertyValue {
    param(
        [AllowNull()]$InputObject,
        [Parameter(Mandatory = $true)][string]$Name,
        $Default = $null
    )

    if (Test-ObjectProperty -InputObject $InputObject -Name $Name) {
        return $InputObject.$Name
    }

    return $Default
}

function Get-ObjectArrayValue {
    param(
        [AllowNull()]$InputObject,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $value = Get-ObjectPropertyValue -InputObject $InputObject -Name $Name
    if ($null -eq $value) {
        return @()
    }

    return @($value)
}

function Format-CodeValue {
    param([AllowNull()]$Value)

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return '`n/a`'
    }

    return ('`{0}`' -f [string]$Value)
}

function Add-BulletLine {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $Lines,

        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $Lines.Add('- ' + $Text)
}

function Add-BlankLine {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $Lines
    )

    $Lines.Add('')
}

function Add-Section {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $Lines,

        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    if ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1] -ne '') {
        $Lines.Add('')
    }

    $Lines.Add('## ' + $Title)
}

function Add-CodeBlock {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $Lines,

        [Parameter(Mandatory = $true)]
        [string[]]$Content
    )

    $Lines.Add('```powershell')
    foreach ($line in $Content) {
        $Lines.Add($line)
    }
    $Lines.Add('```')
}

function Get-CompatibilitiesText {
    param([object[]]$Items)

    if (-not $Items -or $Items.Count -eq 0) {
        return 'nessuna compatibilita consumer dichiarata a catalogo'
    }

    return (($Items | ForEach-Object { Format-CodeValue -Value $_ }) -join ', ')
}

function Get-ItemsText {
    param(
        [object[]]$Items,
        [string]$EmptyText
    )

    if (-not $Items -or $Items.Count -eq 0) {
        return $EmptyText
    }

    return (($Items | ForEach-Object { Format-CodeValue -Value $_ }) -join ', ')
}

$standardDocPath = Join-Path $RepoRoot 'pbi-modular-platform\docs\package-documentation-standard.md'
$standardDoc = @'
# Package Documentation Standard

Ogni package installabile deve contenere un file locale `PACKAGE.md` pensato per chi installa o valuta il modulo.

## Obiettivo

La documentazione del package deve permettere di capire rapidamente:

- cosa si sta installando nel consumer
- quali funzioni copre il package
- quali limiti dichiarati ha
- quali binding o parametri servono
- come validarlo, installarlo e testarlo correttamente
- come usarlo bene dopo l'installazione

## Sezioni minime

- Identita
- Caratteristiche
- Cosa installa
- Prerequisiti dichiarati
- Parametri di binding
- Cosa non fa
- Installazione corretta
- Uso consigliato
- File del package

## Regola di aggiornamento

Quando cambiano `manifest.json`, asset semantic, asset report o comportamento installativo del package, aggiornare anche `PACKAGE.md` nello stesso change set.

## Convenzione operativa

- il contenuto puo essere generato a partire dal manifest
- i dettagli specifici di UX o caveat di business possono essere raffinati manualmente
- il file `README.md` puo restare descrittivo o storico, mentre `PACKAGE.md` e la scheda installativa operativa
'@
Write-Utf8NoBom -Path $standardDocPath -Content $standardDoc

$catalogEntries = @{}
$catalogPaths = Get-ChildItem -Path $RepoRoot -Recurse -Filter modules.json |
    Where-Object { $_.FullName -match '\\catalog\\' } |
    Sort-Object FullName

foreach ($catalogPath in $catalogPaths) {
    $catalog = Get-Content -Raw $catalogPath.FullName | ConvertFrom-Json
    foreach ($package in @(Get-ObjectArrayValue -InputObject $catalog -Name 'packages')) {
        $catalogEntries[[string]$package.moduleId] = [PSCustomObject]@{
            DisplayName           = [string](Get-ObjectPropertyValue -InputObject $package -Name 'displayName' -Default $package.moduleId)
            ConsumerCompatibility = @(Get-ObjectArrayValue -InputObject $package -Name 'consumerCompatibility')
            CatalogVersion        = [string](Get-ObjectPropertyValue -InputObject $package -Name 'version' -Default '')
        }
    }
}

$manifestPaths = Get-ChildItem -Path $RepoRoot -Recurse -Filter manifest.json |
    Where-Object { $_.FullName -match '\\packages\\' } |
    Sort-Object FullName |
    Select-Object -ExpandProperty FullName

foreach ($manifestPath in $manifestPaths) {
    $manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
    $packageDir = Split-Path -Parent $manifestPath
    $packageDocPath = Join-Path $packageDir 'PACKAGE.md'

    $moduleId = [string](Get-ObjectPropertyValue -InputObject $manifest -Name 'moduleId' -Default (Split-Path -Leaf $packageDir))
    $catalogEntry = if ($catalogEntries.ContainsKey($moduleId)) { $catalogEntries[$moduleId] } else { $null }
    $displayName = if ($null -ne $catalogEntry) { [string]$catalogEntry.DisplayName } else { $moduleId }
    $bindingContract = Get-ObjectPropertyValue -InputObject $manifest -Name 'bindingContract'
    $dependencies = Get-ObjectPropertyValue -InputObject $manifest -Name 'dependencies'
    $requires = Get-ObjectPropertyValue -InputObject $manifest -Name 'requires'
    $provides = Get-ObjectPropertyValue -InputObject $manifest -Name 'provides'
    $semanticUx = Get-ObjectPropertyValue -InputObject $manifest -Name 'semanticUx'
    $rendering = Get-ObjectPropertyValue -InputObject $manifest -Name 'rendering'

    $roles = @(Get-ObjectArrayValue -InputObject $bindingContract -Name 'roles')
    $collections = @(Get-ObjectArrayValue -InputObject $bindingContract -Name 'collections')
    $semanticTables = @(Get-ObjectArrayValue -InputObject $provides -Name 'semanticTables')
    $hiddenTables = @(Get-ObjectArrayValue -InputObject $semanticUx -Name 'hiddenTables')
    $dependentModules = @(Get-ObjectArrayValue -InputObject $dependencies -Name 'modules')
    $dependentCapabilities = @(Get-ObjectArrayValue -InputObject $dependencies -Name 'capabilities')
    $requiredMeasures = @(Get-ObjectArrayValue -InputObject $requires -Name 'coreMeasures')
    $requiredColumns = @(Get-ObjectArrayValue -InputObject $requires -Name 'coreColumns')
    $reportPage = Get-ObjectPropertyValue -InputObject $provides -Name 'reportPage'
    $reportDisplayName = [string](Get-ObjectPropertyValue -InputObject $reportPage -Name 'displayName' -Default '')
    $reportName = [string](Get-ObjectPropertyValue -InputObject $reportPage -Name 'name' -Default '')
    $renderingStrategy = [string](Get-ObjectPropertyValue -InputObject $rendering -Name 'strategy' -Default '')
    $bindingMode = [string](Get-ObjectPropertyValue -InputObject $bindingContract -Name 'mode' -Default '')
    $hasReportPage = -not [string]::IsNullOrWhiteSpace($reportDisplayName) -or -not [string]::IsNullOrWhiteSpace($reportName)
    $hasBindingContract = -not [string]::IsNullOrWhiteSpace($bindingMode)
    $hasCollections = $collections.Count -gt 0
    $hasRoles = $roles.Count -gt 0

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# ' + $displayName)

    Add-Section -Lines $lines -Title 'Identita'
    Add-BulletLine -Lines $lines -Text ('Modulo: ' + (Format-CodeValue -Value $moduleId))
    Add-BulletLine -Lines $lines -Text ('Dominio: ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $manifest -Name 'domain' -Default '')))
    Add-BulletLine -Lines $lines -Text ('Versione: ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $manifest -Name 'version' -Default '')))
    Add-BulletLine -Lines $lines -Text ('Tipo: ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $manifest -Name 'type' -Default '')))
    Add-BulletLine -Lines $lines -Text ('Classification: ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $manifest -Name 'classification' -Default '')))
    Add-BulletLine -Lines $lines -Text ('Semantic impact: ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $manifest -Name 'semanticImpact' -Default '')))
    Add-BulletLine -Lines $lines -Text ('Stato: ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $manifest -Name 'status' -Default '')))
    if (-not [string]::IsNullOrWhiteSpace($renderingStrategy)) {
        Add-BulletLine -Lines $lines -Text ('Rendering strategy: ' + (Format-CodeValue -Value $renderingStrategy))
    }
    Add-BulletLine -Lines $lines -Text ('Compatibilita consumer dichiarata: ' + (Get-CompatibilitiesText -Items $(if ($null -ne $catalogEntry) { @($catalogEntry.ConsumerCompatibility) } else { @() })))
    Add-BulletLine -Lines $lines -Text ('Descrizione: ' + [string](Get-ObjectPropertyValue -InputObject $manifest -Name 'description' -Default ''))

    Add-Section -Lines $lines -Title 'Caratteristiche'
    Add-BulletLine -Lines $lines -Text 'Installa asset solo additivi rispetto al consumer target e non richiede riscritture massive del modello.'
    if ($hasBindingContract) {
        if ($bindingMode -eq 'collection-guided') {
            Add-BulletLine -Lines $lines -Text 'Usa binding collection-guided: l''installer guida la scelta di insiemi curati di dimensioni o misure.'
        }
        else {
            Add-BulletLine -Lines $lines -Text ('Usa binding guidato a ruoli espliciti, cosi ogni parametro ha un significato tecnico chiaro (' + (Format-CodeValue -Value $bindingMode) + ').')
        }
    }
    if ($hasCollections) {
        Add-BulletLine -Lines $lines -Text 'Permette di controllare il perimetro installato scegliendo quante colonne o misure esporre.'
    }
    if ($hasReportPage) {
        Add-BulletLine -Lines $lines -Text 'Include una report page starter utile per verificare il modulo subito dopo l''installazione.'
    }
    if (Test-ObjectProperty -InputObject $semanticUx -Name 'primaryTable') {
        Add-BulletLine -Lines $lines -Text ('Espone una facade table business-facing: ' + (Format-CodeValue -Value $semanticUx.primaryTable) + '.')
    }

    Add-Section -Lines $lines -Title 'Cosa installa'
    if ($semanticTables.Count -gt 0) {
        foreach ($tableName in $semanticTables) {
            Add-BulletLine -Lines $lines -Text ('Tabella semantic: ' + (Format-CodeValue -Value $tableName))
        }
    }
    else {
        Add-BulletLine -Lines $lines -Text 'Il manifest non dichiara tabelle semantic installabili.'
    }
    if ($hiddenTables.Count -gt 0) {
        Add-BulletLine -Lines $lines -Text ('Tabelle tecniche nascoste dichiarate: ' + (Get-ItemsText -Items $hiddenTables -EmptyText 'nessuna'))
    }
    if (Test-ObjectProperty -InputObject $semanticUx -Name 'primaryTable') {
        Add-BulletLine -Lines $lines -Text ('Tabella facade visibile: ' + (Format-CodeValue -Value $semanticUx.primaryTable))
    }
    if ($hasReportPage) {
        Add-BulletLine -Lines $lines -Text ('Report page: ' + (Format-CodeValue -Value $reportDisplayName) + ' (' + (Format-CodeValue -Value $reportName) + ')')
    }
    else {
        Add-BulletLine -Lines $lines -Text 'Non installa una report page pronta: il package fornisce solo asset semantic.'
    }

    Add-Section -Lines $lines -Title 'Prerequisiti dichiarati'
    Add-BulletLine -Lines $lines -Text ('Moduli dipendenti: ' + (Get-ItemsText -Items $dependentModules -EmptyText 'nessuno'))
    Add-BulletLine -Lines $lines -Text ('Capability richieste: ' + (Get-ItemsText -Items $dependentCapabilities -EmptyText 'nessuna'))
    Add-BulletLine -Lines $lines -Text ('Core measures richieste: ' + (Get-ItemsText -Items $requiredMeasures -EmptyText 'nessuna dichiarata'))
    Add-BulletLine -Lines $lines -Text ('Core columns richieste: ' + (Get-ItemsText -Items $requiredColumns -EmptyText 'nessuna dichiarata'))

    Add-Section -Lines $lines -Title 'Parametri di binding'
    if (-not $hasRoles -and -not $hasCollections) {
        Add-BulletLine -Lines $lines -Text 'Il package non dichiara un binding contract formale nel manifest.'
    }
    else {
        if ($hasRoles) {
            foreach ($role in $roles) {
                Add-BlankLine -Lines $lines
                $lines.Add('### ' + [string](Get-ObjectPropertyValue -InputObject $role -Name 'label' -Default $role.bindingKey))
                Add-BulletLine -Lines $lines -Text ('Binding key: ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $role -Name 'bindingKey' -Default '')))
                Add-BulletLine -Lines $lines -Text ('Tipo: ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $role -Name 'kind' -Default '')))
                Add-BulletLine -Lines $lines -Text ('Obbligatorio: ' + (Format-CodeValue -Value $(if ([bool](Get-ObjectPropertyValue -InputObject $role -Name 'required' -Default $false)) { 'si' } else { 'no' })))
                if (Test-ObjectProperty -InputObject $role -Name 'semanticRole') {
                    Add-BulletLine -Lines $lines -Text ('Ruolo semantico: ' + (Format-CodeValue -Value $role.semanticRole))
                }
                if (Test-ObjectProperty -InputObject $role -Name 'defaultValue') {
                    Add-BulletLine -Lines $lines -Text ('Default suggerito: ' + (Format-CodeValue -Value $role.defaultValue))
                }
                Add-BulletLine -Lines $lines -Text ('Descrizione: ' + [string](Get-ObjectPropertyValue -InputObject $role -Name 'description' -Default ''))
                $suggestions = @(Get-ObjectArrayValue -InputObject $role -Name 'suggestions')
                if ($suggestions.Count -gt 0) {
                    Add-BulletLine -Lines $lines -Text ('Suggerimenti: ' + (($suggestions | ForEach-Object { Format-CodeValue -Value $_ }) -join ', '))
                }
            }
        }

        if ($hasCollections) {
            foreach ($collection in $collections) {
                Add-BlankLine -Lines $lines
                $lines.Add('### ' + [string](Get-ObjectPropertyValue -InputObject $collection -Name 'label' -Default $collection.id))
                Add-BulletLine -Lines $lines -Text ('Collection id: ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $collection -Name 'id' -Default '')))
                Add-BulletLine -Lines $lines -Text ('Tipo: ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $collection -Name 'kind' -Default '')))
                Add-BulletLine -Lines $lines -Text ('Cardinalita: min ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $collection -Name 'minItems' -Default '')) + ', max ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $collection -Name 'maxItems' -Default '')) + ', visibili di default ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $collection -Name 'defaultVisibleCount' -Default '')))
                Add-BulletLine -Lines $lines -Text ('Pattern binding: ' + (Format-CodeValue -Value ((Get-ObjectPropertyValue -InputObject $collection -Name 'bindingKeyPrefix' -Default '') + '<n>' + (Get-ObjectPropertyValue -InputObject $collection -Name 'bindingKeySuffix' -Default ''))))
                Add-BulletLine -Lines $lines -Text ('Descrizione: ' + [string](Get-ObjectPropertyValue -InputObject $collection -Name 'description' -Default ''))

                foreach ($item in @(Get-ObjectArrayValue -InputObject $collection -Name 'defaultItems')) {
                    $itemDescription = [string](Get-ObjectPropertyValue -InputObject $item -Name 'description' -Default '')
                    $itemDescription = $itemDescription.Trim()
                    if ($itemDescription.EndsWith('.')) {
                        $itemDescription = $itemDescription.Substring(0, $itemDescription.Length - 1)
                    }

                    $itemText = 'Default ' + (Format-CodeValue -Value (Get-ObjectPropertyValue -InputObject $item -Name 'label' -Default 'item')) + ': ' + $itemDescription
                    if (Test-ObjectProperty -InputObject $item -Name 'defaultValue') {
                        $itemText += '; valore suggerito ' + (Format-CodeValue -Value $item.defaultValue)
                    }
                    $itemSuggestions = @(Get-ObjectArrayValue -InputObject $item -Name 'suggestions')
                    if ($itemSuggestions.Count -gt 0) {
                        $itemText += '; suggerimenti ' + (($itemSuggestions | ForEach-Object { Format-CodeValue -Value $_ }) -join ', ')
                    }
                    Add-BulletLine -Lines $lines -Text $itemText
                }
            }
        }
    }

    Add-Section -Lines $lines -Title 'Cosa non fa'
    Add-BulletLine -Lines $lines -Text 'Non sostituisce il semantic core del consumer e non deve essere usato per riscrivere asset core fuori dal perimetro modulare.'
    Add-BulletLine -Lines $lines -Text 'Non crea data source, gateway, refresh pipeline o modellazione esterna al package.'
    Add-BulletLine -Lines $lines -Text 'Non deduce automaticamente il significato di business: binding sbagliati producono risultati coerenti tecnicamente ma sbagliati funzionalmente.'
    if ($hasReportPage) {
        Add-BulletLine -Lines $lines -Text 'La pagina report installata e un punto di partenza tecnico, non un report finale pronto per la distribuzione utente.'
    }
    else {
        Add-BulletLine -Lines $lines -Text 'Non include una pagina report pronta: l''authoring report resta in carico al consumer.'
    }

    Add-Section -Lines $lines -Title 'Installazione corretta'
    Add-BulletLine -Lines $lines -Text ('Parametri CLI base: ' + (Format-CodeValue -Value '-ProjectPath') + ', ' + (Format-CodeValue -Value '-Domain') + ', ' + (Format-CodeValue -Value '-ModuleId'))
    if ($hasBindingContract) {
        Add-BulletLine -Lines $lines -Text ('Parametri CLI consigliati per il binding: ' + (Format-CodeValue -Value '-InteractiveUi') + ', ' + (Format-CodeValue -Value '-SaveBindingProfileAs') + ', ' + (Format-CodeValue -Value '-BindingProfileId') + ', ' + (Format-CodeValue -Value '-MappingFile'))
    }
    if ($hasReportPage) {
        Add-BulletLine -Lines $lines -Text ('Parametro opzionale utile: ' + (Format-CodeValue -Value '-ActivateInstalledPage') + ' per aprire la pagina appena installata come pagina attiva.')
    }

    Add-BlankLine -Lines $lines
    if ($hasBindingContract) {
        Add-CodeBlock -Lines $lines -Content @(
            'pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `',
            '  -Command suggest-bindings `',
            '  -WorkspaceRoot <WORKSPACE_ROOT> `',
            '  -ProjectPath <PROJECT_PATH> `',
            ('  -Domain {0} `' -f (Get-ObjectPropertyValue -InputObject $manifest -Name 'domain' -Default '')),
            ('  -ModuleId {0} `' -f $moduleId),
            '  -InteractiveUi `',
            '  -SaveBindingProfileAs <PROFILE_ID>'
        )

        Add-BlankLine -Lines $lines
        Add-CodeBlock -Lines $lines -Content @(
            'pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `',
            '  -Command validate `',
            '  -WorkspaceRoot <WORKSPACE_ROOT> `',
            '  -ProjectPath <PROJECT_PATH> `',
            ('  -Domain {0} `' -f (Get-ObjectPropertyValue -InputObject $manifest -Name 'domain' -Default '')),
            ('  -ModuleId {0} `' -f $moduleId),
            '  -BindingProfileId <PROFILE_ID>'
        )

        Add-BlankLine -Lines $lines
        $installCommand = @(
            'pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `',
            '  -Command install `',
            '  -WorkspaceRoot <WORKSPACE_ROOT> `',
            '  -ProjectPath <PROJECT_PATH> `',
            ('  -Domain {0} `' -f (Get-ObjectPropertyValue -InputObject $manifest -Name 'domain' -Default '')),
            ('  -ModuleId {0} `' -f $moduleId),
            '  -BindingProfileId <PROFILE_ID>'
        )
        if ($hasReportPage) {
            $installCommand += '  -ActivateInstalledPage'
        }
        Add-CodeBlock -Lines $lines -Content $installCommand
    }
    else {
        Add-CodeBlock -Lines $lines -Content @(
            'pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `',
            '  -Command validate `',
            '  -WorkspaceRoot <WORKSPACE_ROOT> `',
            '  -ProjectPath <PROJECT_PATH> `',
            ('  -Domain {0} `' -f (Get-ObjectPropertyValue -InputObject $manifest -Name 'domain' -Default '')),
            ('  -ModuleId {0}' -f $moduleId)
        )

        Add-BlankLine -Lines $lines
        $installCommand = @(
            'pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `',
            '  -Command install `',
            '  -WorkspaceRoot <WORKSPACE_ROOT> `',
            '  -ProjectPath <PROJECT_PATH> `',
            ('  -Domain {0} `' -f (Get-ObjectPropertyValue -InputObject $manifest -Name 'domain' -Default '')),
            ('  -ModuleId {0}' -f $moduleId)
        )
        if ($hasReportPage) {
            $installCommand += '  -ActivateInstalledPage'
        }
        Add-CodeBlock -Lines $lines -Content $installCommand
    }

    Add-BlankLine -Lines $lines
    Add-CodeBlock -Lines $lines -Content @(
        'pwsh .\pbi-modular-platform\Invoke-PbiModularity.ps1 `',
        '  -Command test `',
        '  -WorkspaceRoot <WORKSPACE_ROOT> `',
        '  -ProjectPath <PROJECT_PATH>'
    )

    Add-Section -Lines $lines -Title 'Uso consigliato'
    Add-BulletLine -Lines $lines -Text 'Parti dai default o dai suggerimenti automatici e restringi il perimetro solo dopo un primo install riuscito.'
    Add-BulletLine -Lines $lines -Text 'Mantieni nascoste le tabelle tecniche `_MOD ...` e usa la facade table come punto di ingresso per chi costruisce report.'
    Add-BulletLine -Lines $lines -Text 'Riesegui `validate` quando cambi binding e `test` dopo ogni install o upgrade.'
    if ($hasCollections) {
        Add-BulletLine -Lines $lines -Text 'Nelle collection-guided evita di esporre piu dimensioni o misure del necessario: troppi item peggiorano UX e manutenzione.'
    }
    if ($hasReportPage) {
        Add-BulletLine -Lines $lines -Text 'Se il package installa una pagina report, usala per smoke test funzionale ma non trattarla come template definitivo di business.'
    }

    Add-Section -Lines $lines -Title 'File del package'
    Add-BulletLine -Lines $lines -Text '`manifest.json`: contratto del modulo, binding, output dichiarati e metadati installativi.'
    Add-BulletLine -Lines $lines -Text '`README.md`: note descrittive, contesto di estrazione o informazioni storiche del package.'
    Add-BulletLine -Lines $lines -Text '`PACKAGE.md`: scheda installativa locale del package.'
    Add-BulletLine -Lines $lines -Text '`semantic/`: asset semantic sorgente che il framework materializza nel consumer.'
    if (Test-Path (Join-Path $packageDir 'report')) {
        Add-BulletLine -Lines $lines -Text '`report/`: eventuali page e visual asset installati nel report consumer.'
    }

    Write-Utf8NoBom -Path $packageDocPath -Content ($lines -join [Environment]::NewLine)
}
