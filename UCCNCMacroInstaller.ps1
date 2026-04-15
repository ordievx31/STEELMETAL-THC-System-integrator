# =============================================================================
# UCCNC STEELMETTLE THC Feedrate Macro Installer
# =============================================================================
# This module provides functions to detect UCCNC installations and
# automatically install the STEELMETTLE THC feedrate Macroloop macro.
#
# Usage:
#   $result = Install-UCCNCFeedrateMacro
#
# =============================================================================

function Find-UCCNCInstallation {
    <#
    .SYNOPSIS
    Locate UCCNC installation directory
    .OUTPUTS
    @{ Path = "C:\UCCNC"; Description = "..." } or $null
    #>

    $candidates = @(
        "C:\UCCNC",
        "D:\UCCNC",
        "$env:ProgramFiles\UCCNC",
        "${env:ProgramFiles(x86)}\UCCNC"
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            $exe = Join-Path $path "UCCNC.exe"
            if (Test-Path $exe) {
                return @{
                    Path = $path
                    Description = "UCCNC installation found at $path"
                }
            }
        }
    }

    return $null
}

function Find-UCCNCProfiles([string]$UCCNCPath) {
    <#
    .SYNOPSIS
    List available UCCNC profiles (subfolders under Profiles)
    .OUTPUTS
    Array of profile name strings, or empty array
    #>
    $profilesRoot = Join-Path $UCCNCPath "Profiles"
    if (-not (Test-Path $profilesRoot)) {
        # Fallback: some installs have Macro_Profiles at root
        $profilesRoot = Join-Path $UCCNCPath "Macro_Profiles"
        if (-not (Test-Path $profilesRoot)) {
            return @()
        }
    }

    $dirs = Get-ChildItem $profilesRoot -Directory -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Name
    if ($dirs) { return @($dirs) }
    return @()
}

function Find-UCCNCMacroloopFolder([string]$UCCNCPath, [string]$ProfileName) {
    <#
    .SYNOPSIS
    Locate the Macroloop folder within a UCCNC profile
    .OUTPUTS
    Full path to Macroloop folder, or $null
    #>

    # Common paths depending on UCCNC version
    $candidates = @(
        (Join-Path (Join-Path (Join-Path $UCCNCPath "Profiles") $ProfileName) "Macroloop"),
        (Join-Path (Join-Path $UCCNCPath "Macro_Profiles") "Macroloop"),
        (Join-Path $UCCNCPath "Macroloop")
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return $path
        }
    }

    # If no Macroloop folder exists, create it in the first valid profile path
    $profileDir = Join-Path (Join-Path $UCCNCPath "Profiles") $ProfileName
    if (Test-Path $profileDir) {
        $macroloopDir = Join-Path $profileDir "Macroloop"
        return $macroloopDir  # Will be created during install
    }

    return $null
}

function New-UCCNCProfileSelectionDialog([string[]]$Profiles) {
    <#
    .SYNOPSIS
    Display WinForms dialog to select which UCCNC profile to target
    #>

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "STEELMETTLE THC: Install UCCNC Macro"
    $form.Width = 500
    $form.Height = 280
    $form.StartPosition = "CenterParent"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $accentColor = [System.Drawing.Color]::FromArgb(88, 84, 40)
    $textColor = [System.Drawing.Color]::White

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Select UCCNC Profile:"
    $lbl.Location = [System.Drawing.Point]::new(16, 18)
    $lbl.Size = [System.Drawing.Size]::new(450, 24)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($lbl)

    $cmb = New-Object System.Windows.Forms.ComboBox
    $cmb.Location = [System.Drawing.Point]::new(16, 50)
    $cmb.Size = [System.Drawing.Size]::new(450, 30)
    $cmb.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

    foreach ($p in $Profiles) {
        [void]$cmb.Items.Add($p)
    }
    if ($cmb.Items.Count -gt 0) { $cmb.SelectedIndex = 0 }
    $form.Controls.Add($cmb)

    $instrLbl = New-Object System.Windows.Forms.Label
    $instrLbl.Text = @"
The Macroloop macro file will be copied to the selected
profile. After installation, enable the Macro Loop Plugin
in UCCNC: Configure > General Settings > Plugins.

Restart UCCNC after installation to activate.
"@
    $instrLbl.Location = [System.Drawing.Point]::new(16, 92)
    $instrLbl.Size = [System.Drawing.Size]::new(450, 80)
    $instrLbl.TextAlign = "TopLeft"
    $form.Controls.Add($instrLbl)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Install"
    $btnOk.Location = [System.Drawing.Point]::new(278, 204)
    $btnOk.Size = [System.Drawing.Size]::new(90, 32)
    $btnOk.BackColor = $accentColor
    $btnOk.ForeColor = $textColor
    $btnOk.FlatStyle = "Flat"
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $btnOk
    $form.Controls.Add($btnOk)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = [System.Drawing.Point]::new(376, 204)
    $btnCancel.Size = [System.Drawing.Size]::new(90, 32)
    $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(122, 58, 34)
    $btnCancel.ForeColor = $textColor
    $btnCancel.FlatStyle = "Flat"
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $btnCancel
    $form.Controls.Add($btnCancel)

    $result = $form.ShowDialog()
    $selectedItem = $cmb.SelectedItem
    $form.Dispose()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $selectedItem) {
        return [string]$selectedItem
    }
    return $null
}

function Install-UCCNCFeedrateMacro {
    <#
    .SYNOPSIS
    Auto-deploy UCCNC feedrate macro. Detects installation, selects profile
    automatically, backs up existing files, and copies the macro - all silently.
    Only shows a dialog if multiple profiles exist and cannot auto-select.

    .OUTPUTS
    @{ Success = $true; Message = "..."; MacroPath = "..." } or failure object
    #>

    # Step 1: Locate UCCNC installation (silent)
    $installation = Find-UCCNCInstallation

    if (-not $installation) {
        return @{ Success = $false; Message = "UCCNC installation not found in common locations (C:\UCCNC, D:\UCCNC, Program Files)" }
    }

    # Step 2: Auto-select profile
    [string[]]$profiles = @(Find-UCCNCProfiles -UCCNCPath $installation.Path)

    $selectedProfile = $null
    if ($profiles.Count -eq 0) {
        $selectedProfile = "Default"
    } elseif ($profiles.Count -eq 1) {
        $selectedProfile = $profiles[0]
    } else {
        # Multiple profiles - only case where we need user input
        Add-Type -AssemblyName System.Windows.Forms
        $selectedProfile = New-UCCNCProfileSelectionDialog -Profiles $profiles
        if (-not $selectedProfile) {
            return @{ Success = $false; Message = "Multiple UCCNC profiles found - user cancelled selection" }
        }
    }

    # Step 3: Locate or create Macroloop folder
    $macroloopFolder = Find-UCCNCMacroloopFolder -UCCNCPath $installation.Path -ProfileName $selectedProfile

    if (-not $macroloopFolder) {
        return @{ Success = $false; Message = "Could not determine Macroloop folder for profile '$selectedProfile'" }
    }

    if (-not (Test-Path $macroloopFolder)) {
        try {
            New-Item -ItemType Directory -Path $macroloopFolder -Force | Out-Null
        } catch {
            return @{ Success = $false; Message = "Failed to create Macroloop folder: $_" }
        }
    }

    # Step 4: Find source template
    $sourceFileName = "UCCNC_FEEDRATE_THC_MACRO.txt"
    $destFileName = "Macroloop.txt"

    $integrationDir = if ($baseDir) { $baseDir } elseif ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $sourceFile = Join-Path (Join-Path $integrationDir "PoKeys") $sourceFileName

    if (-not (Test-Path $sourceFile)) {
        return @{ Success = $false; Message = "UCCNC macro template not found: $sourceFile" }
    }

    # Step 5: Backup existing Macroloop.txt if present
    $destFile = Join-Path $macroloopFolder $destFileName

    if (Test-Path $destFile) {
        $backupName = "Macroloop_backup_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt"
        $backupPath = Join-Path $macroloopFolder $backupName
        try {
            Copy-Item -Path $destFile -Destination $backupPath -Force
        } catch {
            # Non-fatal
        }
    }

    # Step 6: Copy macro file
    try {
        Copy-Item -Path $sourceFile -Destination $destFile -Force

        if ($null -ne $logDir) {
            $logMsg = "UCCNC auto-deploy: $sourceFile -> $destFile (profile: $selectedProfile)"
            (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + " $logMsg" | Add-Content (Join-Path $logDir 'integrator.log') -Encoding ASCII
        }
    } catch {
        return @{ Success = $false; Message = "Failed to copy macro file: $_" }
    }

    return @{
        Success = $true
        Message = "UCCNC macro deployed to $destFile (profile: $selectedProfile)"
        MacroPath = $destFile
        UCCNCPath = $installation.Path
        Profile = $selectedProfile
    }
}

if ($null -ne $ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function @(
        'Find-UCCNCInstallation',
        'Find-UCCNCProfiles',
        'Install-UCCNCFeedrateMacro'
    )
}
