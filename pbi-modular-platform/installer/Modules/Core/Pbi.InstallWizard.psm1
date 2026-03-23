function Get-PbiInstallWizardDefaultProfileId {
    param(
        [Parameter(Mandatory = $true)]$Project,
        [Parameter(Mandatory = $true)]$Module,
        [string]$PreferredProfileId
    )

    $baseProfileId = if (-not [string]::IsNullOrWhiteSpace($PreferredProfileId)) {
        $PreferredProfileId.Trim()
    }
    else {
        ("{0}_{1}_wizard" -f $Module.ModuleId, $Project.ProjectId)
    }

    $existingProfileIds = @(
        Get-PbiProjectBindingProfiles -Project $Project -ModuleId $Module.ModuleId |
            ForEach-Object { [string]$_.ProfileId }
    )

    if ($existingProfileIds -notcontains $baseProfileId) {
        return $baseProfileId
    }

    $suffix = 2
    while ($true) {
        $candidateProfileId = ("{0}_{1}" -f $baseProfileId, $suffix)
        if ($existingProfileIds -notcontains $candidateProfileId) {
            return $candidateProfileId
        }

        $suffix += 1
    }
}

function Get-PbiInstallWizardModulePreCheck {
    param(
        [string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [string]$Domain,
        [Parameter(Mandatory = $true)][string]$ModuleId
    )

    $project = Resolve-PbiConsumerProject -ProjectPath $ProjectPath
    $module = Get-PbiSingleModule -WorkspaceRoot $WorkspaceRoot -Domain $Domain -ModuleId $ModuleId
    $baseMappings = Resolve-PbiModuleMapping -Module $module -Project $project -OverrideMapping $null
    $validation = Test-PbiModuleRequirements -Project $project -Manifest $module.Manifest -ResolvedMappings $baseMappings
    $measureConflicts = Test-PbiModuleMeasureConflicts -Project $project -Module $module -Manifest $module.Manifest -ResolvedMappings $baseMappings
    $bindingContract = Get-PbiModuleBindingContract -Manifest $module.Manifest
    $installed = Test-PbiModuleAlreadyInstalled -Project $project -Module $module

    $reportPageName = ""
    if ($module.Manifest.provides -and $module.Manifest.provides.reportPage) {
        if ($module.Manifest.provides.reportPage.name) {
            $reportPageName = [string]$module.Manifest.provides.reportPage.name
        }
        else {
            $reportPageName = [string]$module.Manifest.provides.reportPage
        }
    }

    return [PSCustomObject]@{
        Project                  = $project
        Module                   = $module
        Installed                = $installed
        DefaultMappings          = $baseMappings
        MissingMeasures          = @($validation.MissingMeasures)
        MissingColumns           = @($validation.MissingColumns)
        MeasureConflicts         = @($measureConflicts.Conflicts)
        IsDefaultValidationValid = ($validation.IsValid -and -not $measureConflicts.HasConflicts)
        BindingRoleCount         = @($bindingContract.roles).Count
        RequiredMeasureCount     = @($module.Manifest.requires.coreMeasures).Count
        RequiredColumnCount      = @($module.Manifest.requires.coreColumns).Count
        SemanticTables           = @($module.Manifest.provides.semanticTables)
        ReportPage               = $reportPageName
        PrimaryTable             = if ($module.Manifest.semanticUx.primaryTable) { [string]$module.Manifest.semanticUx.primaryTable } else { "" }
        HiddenTables             = @($module.Manifest.semanticUx.hiddenTables)
    }
}

function ConvertTo-PbiInstallWizardSummaryText {
    param([Parameter(Mandatory = $true)]$State)

    $lines = New-Object System.Collections.Generic.List[string]
    $preCheck = $State.PreCheck
    $module = $preCheck.Module
    $project = $preCheck.Project

    $lines.Add(("Project: {0}" -f $project.ProjectId))
    $lines.Add(("PBIP: {0}" -f $project.PbipPath))
    $lines.Add(("Domain: {0}" -f $module.Domain))
    $lines.Add(("Module: {0}" -f $module.ModuleId))
    $lines.Add(("Display name: {0}" -f $module.DisplayName))
    $lines.Add(("Version: {0}" -f $module.Version))
    $lines.Add(("Type: {0}" -f $module.Type))
    $lines.Add(("Classification: {0}" -f $module.Classification))
    $lines.Add(("Installed already: {0}" -f $(if ($preCheck.Installed) { "Yes" } else { "No" })))
    $lines.Add(("Package root: {0}" -f $module.PackageRoot))
    $lines.Add("")

    if (-not [string]::IsNullOrWhiteSpace([string]$module.Manifest.description)) {
        $lines.Add("Description:")
        $lines.Add([string]$module.Manifest.description)
        $lines.Add("")
    }

    $lines.Add(("Primary table: {0}" -f $(if ([string]::IsNullOrWhiteSpace($preCheck.PrimaryTable)) { "(not declared)" } else { $preCheck.PrimaryTable })))
    $lines.Add(("Semantic tables: {0}" -f $(if ($preCheck.SemanticTables.Count -gt 0) { ($preCheck.SemanticTables -join ", ") } else { "(none)" })))
    if (-not [string]::IsNullOrWhiteSpace($preCheck.ReportPage)) {
        $lines.Add(("Report page: {0}" -f $preCheck.ReportPage))
    }
    $lines.Add(("Binding roles: {0}" -f $preCheck.BindingRoleCount))
    $lines.Add(("Required measures: {0}" -f $preCheck.RequiredMeasureCount))
    $lines.Add(("Required columns: {0}" -f $preCheck.RequiredColumnCount))
    $lines.Add("")

    $lines.Add("Pre-check:")
    if ($preCheck.IsDefaultValidationValid) {
        $lines.Add("Default mappings already satisfy all requirements.")
    }
    else {
        if ($preCheck.MissingMeasures.Count -gt 0) {
            $lines.Add(("Missing measures with default mappings: {0}" -f (($preCheck.MissingMeasures | Sort-Object) -join ", ")))
        }
        if ($preCheck.MissingColumns.Count -gt 0) {
            $lines.Add(("Missing columns with default mappings: {0}" -f (($preCheck.MissingColumns | Sort-Object) -join ", ")))
        }
        if ($preCheck.MeasureConflicts.Count -gt 0) {
            $lines.Add(("Measure conflicts detected: {0}" -f (($preCheck.MeasureConflicts | Sort-Object) -join ", ")))
        }
    }
    $lines.Add("")

    $lines.Add("Bindings:")
    if ([string]::IsNullOrWhiteSpace([string]$State.BindingProfileId)) {
        $lines.Add("No binding profile selected yet. Use Configure Bindings.")
    }
    else {
        $lines.Add(("Profile: {0}" -f $State.BindingProfileId))
        $currentMappings = ConvertTo-PbiResolvedMappings -Mappings $State.ResolvedMappings
        foreach ($sectionName in @("coreMeasures", "coreColumns")) {
            $section = Get-PbiResolvedMappingSection -ResolvedMappings $currentMappings -SectionName $sectionName
            foreach ($key in @($section.Keys | Sort-Object)) {
                $lines.Add(("  {0} -> {1}" -f $key, $section[$key]))
            }
        }
    }
    $lines.Add("")

    $lines.Add("Validation:")
    if ($null -eq $State.ValidationResult) {
        $lines.Add("Not validated yet.")
    }
    elseif ($State.ValidationResult.IsValid) {
        $lines.Add("PASS")
    }
    else {
        $lines.Add("FAIL")
        if (-not [string]::IsNullOrWhiteSpace([string]$State.ValidationResult.MissingMeasures)) {
            $lines.Add(("Missing measures: {0}" -f $State.ValidationResult.MissingMeasures))
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$State.ValidationResult.MissingColumns)) {
            $lines.Add(("Missing columns: {0}" -f $State.ValidationResult.MissingColumns))
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$State.ValidationResult.MeasureConflicts)) {
            $lines.Add(("Measure conflicts: {0}" -f $State.ValidationResult.MeasureConflicts))
        }
    }

    if ($null -ne $State.InstallResult) {
        $lines.Add("")
        $lines.Add("Install result:")
        $lines.Add(("Action: {0}" -f $State.InstallResult.Action))
        if ($State.InstallResult.SnapshotId) {
            $lines.Add(("Snapshot: {0}" -f $State.InstallResult.SnapshotId))
        }
        if ($State.InstallResult.Governance -and $State.InstallResult.Governance.status) {
            $lines.Add(("Governance: {0}" -f $State.InstallResult.Governance.status))
        }
        if ($State.InstallResult.LogPath) {
            $lines.Add(("Log: {0}" -f $State.InstallResult.LogPath))
        }
    }

    return ($lines -join [Environment]::NewLine)
}

function Invoke-PbiInstallWizard {
    param(
        [string]$WorkspaceRoot,
        [string]$ProjectPath,
        [string]$Domain,
        [string]$ModuleId,
        [string]$BindingProfileId,
        [string]$SaveBindingProfileAs,
        [switch]$ActivateInstalledPage,
        [switch]$Force
    )

    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
    }
    catch {
        throw "Install wizard UI is not available on this host."
    }

    $allModules = @(Get-PbiModuleList -WorkspaceRoot $WorkspaceRoot)
    if ($allModules.Count -eq 0) {
        throw "No installable modules were found in the discovered catalogs."
    }

    $wizardModules = @(
        foreach ($moduleRecord in $allModules) {
            [PSCustomObject]@{
                Label    = ("{0} | {1} | {2}" -f $moduleRecord.Domain, $moduleRecord.DisplayName, $moduleRecord.ModuleId)
                Domain   = $moduleRecord.Domain
                ModuleId = $moduleRecord.ModuleId
                Module   = $moduleRecord
            }
        }
    )

    $state = [ordered]@{
        WorkspaceRoot        = $WorkspaceRoot
        ProjectPath          = $ProjectPath
        Domain               = $Domain
        ModuleId             = $ModuleId
        BindingProfileId     = $BindingProfileId
        SaveBindingProfileAs = $SaveBindingProfileAs
        ResolvedMappings     = $null
        ValidationResult     = $null
        InstallResult        = $null
        PreCheck             = $null
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "PBI Modularity Install Wizard"
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.Size = [System.Drawing.Size]::new(980, 760)
    $form.MinimumSize = [System.Drawing.Size]::new(920, 700)
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font

    $headerLabel = New-Object System.Windows.Forms.Label
    $headerLabel.Text = "Select target project and package"
    $headerLabel.Font = [System.Drawing.Font]::new("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $headerLabel.AutoSize = $true
    $headerLabel.Location = [System.Drawing.Point]::new(16, 14)

    $stepLabel = New-Object System.Windows.Forms.Label
    $stepLabel.Text = "Step 1 of 3"
    $stepLabel.AutoSize = $true
    $stepLabel.Location = [System.Drawing.Point]::new(18, 44)

    $selectionPanel = New-Object System.Windows.Forms.Panel
    $selectionPanel.Location = [System.Drawing.Point]::new(16, 76)
    $selectionPanel.Size = [System.Drawing.Size]::new(930, 290)

    $projectLabel = New-Object System.Windows.Forms.Label
    $projectLabel.Text = "Project (.pbip)"
    $projectLabel.AutoSize = $true
    $projectLabel.Location = [System.Drawing.Point]::new(0, 8)

    $projectTextBox = New-Object System.Windows.Forms.TextBox
    $projectTextBox.Size = [System.Drawing.Size]::new(720, 27)
    $projectTextBox.Location = [System.Drawing.Point]::new(0, 30)
    if (-not [string]::IsNullOrWhiteSpace($ProjectPath)) {
        $projectTextBox.Text = $ProjectPath
    }

    $browseProjectButton = New-Object System.Windows.Forms.Button
    $browseProjectButton.Text = "Browse"
    $browseProjectButton.Size = [System.Drawing.Size]::new(96, 30)
    $browseProjectButton.Location = [System.Drawing.Point]::new(730, 28)

    $domainLabel = New-Object System.Windows.Forms.Label
    $domainLabel.Text = "Domain"
    $domainLabel.AutoSize = $true
    $domainLabel.Location = [System.Drawing.Point]::new(0, 72)

    $domainCombo = New-Object System.Windows.Forms.ComboBox
    $domainCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $domainCombo.Size = [System.Drawing.Size]::new(220, 27)
    $domainCombo.Location = [System.Drawing.Point]::new(0, 94)

    $moduleLabel = New-Object System.Windows.Forms.Label
    $moduleLabel.Text = "Package"
    $moduleLabel.AutoSize = $true
    $moduleLabel.Location = [System.Drawing.Point]::new(236, 72)

    $moduleCombo = New-Object System.Windows.Forms.ComboBox
    $moduleCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $moduleCombo.Size = [System.Drawing.Size]::new(590, 27)
    $moduleCombo.Location = [System.Drawing.Point]::new(236, 94)

    $selectionDetails = New-Object System.Windows.Forms.TextBox
    $selectionDetails.Multiline = $true
    $selectionDetails.ReadOnly = $true
    $selectionDetails.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $selectionDetails.Size = [System.Drawing.Size]::new(826, 136)
    $selectionDetails.Location = [System.Drawing.Point]::new(0, 138)
    $selectionDetails.Text = "Select a package to preview its scope before running the pre-check."

    $reviewPanel = New-Object System.Windows.Forms.Panel
    $reviewPanel.Location = [System.Drawing.Point]::new(16, 76)
    $reviewPanel.Size = [System.Drawing.Size]::new(930, 564)
    $reviewPanel.Visible = $false

    $summaryBox = New-Object System.Windows.Forms.TextBox
    $summaryBox.Multiline = $true
    $summaryBox.ReadOnly = $true
    $summaryBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $summaryBox.Size = [System.Drawing.Size]::new(930, 420)
    $summaryBox.Location = [System.Drawing.Point]::new(0, 0)

    $activatePageCheckBox = New-Object System.Windows.Forms.CheckBox
    $activatePageCheckBox.Text = "Activate installed report page when the package provides one"
    $activatePageCheckBox.AutoSize = $true
    $activatePageCheckBox.Location = [System.Drawing.Point]::new(0, 432)
    $activatePageCheckBox.Checked = [bool]$ActivateInstalledPage

    $forceInstallCheckBox = New-Object System.Windows.Forms.CheckBox
    $forceInstallCheckBox.Text = "Force install when assets are already present"
    $forceInstallCheckBox.AutoSize = $true
    $forceInstallCheckBox.Location = [System.Drawing.Point]::new(0, 458)
    $forceInstallCheckBox.Checked = [bool]$Force

    $reviewStatusLabel = New-Object System.Windows.Forms.Label
    $reviewStatusLabel.Text = "Bindings not configured yet."
    $reviewStatusLabel.AutoSize = $true
    $reviewStatusLabel.Location = [System.Drawing.Point]::new(0, 490)

    $selectionPanel.Controls.AddRange(@(
            $projectLabel,
            $projectTextBox,
            $browseProjectButton,
            $domainLabel,
            $domainCombo,
            $moduleLabel,
            $moduleCombo,
            $selectionDetails
        ))

    $reviewPanel.Controls.AddRange(@(
            $summaryBox,
            $activatePageCheckBox,
            $forceInstallCheckBox,
            $reviewStatusLabel
        ))

    $backButton = New-Object System.Windows.Forms.Button
    $backButton.Text = "Back"
    $backButton.Size = [System.Drawing.Size]::new(96, 34)
    $backButton.Location = [System.Drawing.Point]::new(538, 652)
    $backButton.Enabled = $false

    $nextButton = New-Object System.Windows.Forms.Button
    $nextButton.Text = "Check"
    $nextButton.Size = [System.Drawing.Size]::new(120, 34)
    $nextButton.Location = [System.Drawing.Point]::new(644, 652)

    $actionButton = New-Object System.Windows.Forms.Button
    $actionButton.Text = "Configure Bindings"
    $actionButton.Size = [System.Drawing.Size]::new(168, 34)
    $actionButton.Location = [System.Drawing.Point]::new(772, 652)
    $actionButton.Enabled = $false

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Close"
    $cancelButton.Size = [System.Drawing.Size]::new(96, 34)
    $cancelButton.Location = [System.Drawing.Point]::new(848, 12)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $form.Controls.AddRange(@(
            $headerLabel,
            $stepLabel,
            $selectionPanel,
            $reviewPanel,
            $backButton,
            $nextButton,
            $actionButton,
            $cancelButton
        ))
    $form.CancelButton = $cancelButton

    $setSelectionDetails = {
        $selectedModuleItem = $moduleCombo.SelectedItem
        if ($null -eq $selectedModuleItem) {
            $selectionDetails.Text = "Select a package to preview its scope before running the pre-check."
            return
        }

        $selectedModule = $selectedModuleItem.Module

        $moduleLines = @(
            ("Domain: {0}" -f $selectedModule.Domain),
            ("Module: {0}" -f $selectedModule.ModuleId),
            ("Display name: {0}" -f $selectedModule.DisplayName),
            ("Version: {0}" -f $selectedModule.Version),
            ("Type: {0}" -f $selectedModule.Type),
            ("Classification: {0}" -f $selectedModule.Classification),
            ("Status: {0}" -f $selectedModule.Status),
            ("Package root: {0}" -f $selectedModule.PackageRoot),
            "",
            ("Description: {0}" -f $selectedModule.Manifest.description)
        )

        $selectionDetails.Text = ($moduleLines -join [Environment]::NewLine)
    }

    $refreshModuleItems = {
        $currentDomain = if ($domainCombo.SelectedItem) { [string]$domainCombo.SelectedItem } else { "" }
        $moduleCombo.BeginUpdate()
        $moduleCombo.Items.Clear()

        $filteredModules = if ([string]::IsNullOrWhiteSpace($currentDomain)) {
            $wizardModules
        }
        else {
            @($wizardModules | Where-Object { $_.Domain -eq $currentDomain })
        }

        foreach ($moduleItem in $filteredModules) {
            [void]$moduleCombo.Items.Add($moduleItem)
        }

        $moduleCombo.DisplayMember = "Label"
        $moduleCombo.ValueMember = "ModuleId"

        if (-not [string]::IsNullOrWhiteSpace($state.ModuleId)) {
            $preselectedModule = $filteredModules | Where-Object { $_.ModuleId -eq $state.ModuleId } | Select-Object -First 1
            if ($preselectedModule) {
                $moduleCombo.SelectedItem = $preselectedModule
            }
        }

        if ($null -eq $moduleCombo.SelectedItem -and $moduleCombo.Items.Count -gt 0) {
            $moduleCombo.SelectedIndex = 0
        }

        $moduleCombo.EndUpdate()
        & $setSelectionDetails
    }

    foreach ($domainName in @($wizardModules.Domain | Sort-Object -Unique)) {
        [void]$domainCombo.Items.Add($domainName)
    }

    if (-not [string]::IsNullOrWhiteSpace($Domain) -and ($domainCombo.Items -contains $Domain)) {
        $domainCombo.SelectedItem = $Domain
    }
    elseif ($domainCombo.Items.Count -gt 0) {
        $domainCombo.SelectedIndex = 0
    }

    $domainCombo.Add_SelectedIndexChanged({
            $state.Domain = if ($domainCombo.SelectedItem) { [string]$domainCombo.SelectedItem } else { "" }
            & $refreshModuleItems
        })
    $moduleCombo.Add_SelectedIndexChanged({
            if ($moduleCombo.SelectedItem) {
                $state.ModuleId = [string]$moduleCombo.SelectedItem.ModuleId
            }
            & $setSelectionDetails
        })

    & $refreshModuleItems

    if (-not [string]::IsNullOrWhiteSpace($Domain) -and -not [string]::IsNullOrWhiteSpace($ModuleId)) {
        $domainCombo.Enabled = $false
        $moduleCombo.Enabled = $false
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Domain)) {
        $domainCombo.Enabled = $false
    }

    $showReviewStep = {
        $selectionPanel.Visible = $false
        $reviewPanel.Visible = $true
        $headerLabel.Text = "Review, bind, validate, and install"
        $stepLabel.Text = "Step 3 of 3"
        $backButton.Enabled = $true
        $nextButton.Enabled = $false
        $actionButton.Enabled = $true
        $actionButton.Text = "Configure Bindings"
    }

    $showSelectionStep = {
        $selectionPanel.Visible = $true
        $reviewPanel.Visible = $false
        $headerLabel.Text = "Select target project and package"
        $stepLabel.Text = "Step 1 of 3"
        $backButton.Enabled = $false
        $nextButton.Enabled = $true
        $nextButton.Text = "Check"
        $actionButton.Enabled = $false
        $actionButton.Text = "Configure Bindings"
    }

    $updateReviewState = {
        if ($null -eq $state.PreCheck) {
            return
        }

        $summaryBox.Text = ConvertTo-PbiInstallWizardSummaryText -State $state

        if ($null -eq $state.InstallResult) {
            if ($null -eq $state.ValidationResult) {
                $reviewStatusLabel.Text = "Bindings not configured yet."
                $reviewStatusLabel.ForeColor = [System.Drawing.Color]::Black
                $actionButton.Text = "Configure Bindings"
                $nextButton.Enabled = $false
            }
            elseif ($state.ValidationResult.IsValid) {
                $reviewStatusLabel.Text = ("Bindings ready. Install profile '{0}'." -f $state.BindingProfileId)
                $reviewStatusLabel.ForeColor = [System.Drawing.Color]::ForestGreen
                $actionButton.Text = "Configure Bindings"
                $nextButton.Enabled = $true
                $nextButton.Text = "Install"
            }
            else {
                $reviewStatusLabel.Text = "Bindings saved but validation failed. Fix them before install."
                $reviewStatusLabel.ForeColor = [System.Drawing.Color]::Firebrick
                $actionButton.Text = "Configure Bindings"
                $nextButton.Enabled = $false
            }
        }
        else {
            $reviewStatusLabel.Text = "Install completed."
            $reviewStatusLabel.ForeColor = [System.Drawing.Color]::ForestGreen
            $actionButton.Text = "Close"
            $nextButton.Enabled = $false
        }
    }

    $browseProjectButton.Add_Click({
            $dialog = New-Object System.Windows.Forms.OpenFileDialog
            $dialog.Filter = "Power BI Project (*.pbip)|*.pbip"
            $dialog.CheckFileExists = $true
            $dialog.Multiselect = $false
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $projectTextBox.Text = $dialog.FileName
            }
        })

    $backButton.Add_Click({
            & $showSelectionStep
        })

    $actionButton.Add_Click({
            if ($null -ne $state.InstallResult) {
                $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $form.Close()
                return
            }

            try {
                if ($null -eq $state.PreCheck) {
                    return
                }

                $baseMappings = if ($null -ne $state.ResolvedMappings) {
                    $state.ResolvedMappings
                }
                else {
                    $state.PreCheck.DefaultMappings
                }

                $suggestionSet = Get-PbiModuleBindingSuggestions -Project $state.PreCheck.Project -Module $state.PreCheck.Module -BaseMappings $baseMappings
                $defaultProfileId = Get-PbiInstallWizardDefaultProfileId -Project $state.PreCheck.Project -Module $state.PreCheck.Module -PreferredProfileId $state.SaveBindingProfileAs
                $wizardResult = Invoke-PbiInteractiveBindingUiWizard -SuggestionSet $suggestionSet -Project $state.PreCheck.Project -Module $state.PreCheck.Module -DefaultProfileId $defaultProfileId
                $state.ResolvedMappings = ConvertTo-PbiResolvedMappings -Mappings $wizardResult.ResolvedMappings

                if (-not [string]::IsNullOrWhiteSpace([string]$wizardResult.SavedProfileId)) {
                    $state.BindingProfileId = [string]$wizardResult.SavedProfileId
                }
                else {
                    $savedProfile = Save-PbiBindingProfile -Project $state.PreCheck.Project -Module $state.PreCheck.Module -ProfileId $defaultProfileId -ResolvedMappings $state.ResolvedMappings -BindingMode "install-wizard"
                    $state.BindingProfileId = [string]$savedProfile.Profile.profileId
                }

                $state.ValidationResult = Invoke-PbiProjectValidation -WorkspaceRoot $state.WorkspaceRoot -ProjectPath $state.PreCheck.Project.PbipPath -Domain $state.PreCheck.Module.Domain -ModuleId $state.PreCheck.Module.ModuleId -BindingProfileId $state.BindingProfileId | Select-Object -First 1
                & $updateReviewState
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show(
                    $_.Exception.Message,
                    "Binding wizard",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                ) | Out-Null
            }
        })

    $nextButton.Add_Click({
            if ($reviewPanel.Visible) {
                try {
                    if ($null -eq $state.ValidationResult -or -not $state.ValidationResult.IsValid) {
                        [System.Windows.Forms.MessageBox]::Show(
                            "Configure bindings and validate them before install.",
                            "Install blocked",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Warning
                        ) | Out-Null
                        return
                    }

                    $state.InstallResult = Invoke-PbiModuleInstallOperation -WorkspaceRoot $state.WorkspaceRoot -ProjectPath $state.PreCheck.Project.PbipPath -Domain $state.PreCheck.Module.Domain -ModuleId $state.PreCheck.Module.ModuleId -BindingProfileId $state.BindingProfileId -ActivateInstalledPage:$activatePageCheckBox.Checked -Force:$forceInstallCheckBox.Checked
                    & $updateReviewState
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        $_.Exception.Message,
                        "Install failed",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    ) | Out-Null
                }

                return
            }

            try {
                $selectedModuleItem = $moduleCombo.SelectedItem
                $selectedModule = if ($selectedModuleItem) { $selectedModuleItem.Module } else { $null }
                if ([string]::IsNullOrWhiteSpace([string]$projectTextBox.Text)) {
                    throw "Select a target PBIP project first."
                }
                if ($null -eq $selectedModule) {
                    throw "Select a package first."
                }

                $state.ProjectPath = [string]$projectTextBox.Text
                $state.Domain = [string]$selectedModule.Domain
                $state.ModuleId = [string]$selectedModule.ModuleId
                $state.PreCheck = Get-PbiInstallWizardModulePreCheck -WorkspaceRoot $state.WorkspaceRoot -ProjectPath $state.ProjectPath -Domain $state.Domain -ModuleId $state.ModuleId
                $state.ValidationResult = $null
                $state.InstallResult = $null
                $state.BindingProfileId = if ($BindingProfileId) { $BindingProfileId } else { "" }
                $state.ResolvedMappings = $null
                & $updateReviewState
                & $showReviewStep
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show(
                    $_.Exception.Message,
                    "Pre-check failed",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
            }
        })

    & $showSelectionStep

    $dialogResult = $form.ShowDialog()
    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Cancel) {
        throw "Install wizard was cancelled by the user."
    }

    return [PSCustomObject]@{
        Project          = if ($state.PreCheck) { $state.PreCheck.Project } else { $null }
        Module           = if ($state.PreCheck) { $state.PreCheck.Module } else { $null }
        BindingProfileId = $state.BindingProfileId
        ValidationResult = $state.ValidationResult
        InstallResult    = $state.InstallResult
    }
}

Export-ModuleMember -Function Get-PbiInstallWizardModulePreCheck, Invoke-PbiInstallWizard
