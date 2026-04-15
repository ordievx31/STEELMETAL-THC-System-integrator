# =============================================================================
# LINUXCNC STEELMETTLE THC Feedrate HAL Exporter
# =============================================================================
# Since LinuxCNC runs on Linux, this Windows-side script exports a customized
# HAL configuration file to a USB drive, network share, or local folder so the
# user can copy it to their LinuxCNC machine.
#
# Usage:
#   $result = Export-LinuxCNCFeedrateBus
#
# =============================================================================

function New-LinuxCNCExportDialog {
    <#
    .SYNOPSIS
    WinForms dialog to configure LinuxCNC HAL export options:
      - Max feedrate (for gain calculation)
      - Hardware type (Mesa GPIO or parallel port)
      - Destination folder
    .OUTPUTS
    Hashtable with settings, or $null if cancelled
    #>

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $accentColor = [System.Drawing.Color]::FromArgb(88, 84, 40)
    $textColor = [System.Drawing.Color]::White

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "STEELMETTLE THC: Export LinuxCNC HAL Config"
    $form.Width = 520
    $form.Height = 380
    $form.StartPosition = "CenterParent"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    # --- Max feedrate ---
    $lblFeed = New-Object System.Windows.Forms.Label
    $lblFeed.Text = "Max cutting feedrate (units/min):"
    $lblFeed.Location = [System.Drawing.Point]::new(16, 18)
    $lblFeed.Size = [System.Drawing.Size]::new(260, 22)
    $lblFeed.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $form.Controls.Add($lblFeed)

    $txtFeed = New-Object System.Windows.Forms.TextBox
    $txtFeed.Text = "500"
    $txtFeed.Location = [System.Drawing.Point]::new(280, 16)
    $txtFeed.Size = [System.Drawing.Size]::new(100, 24)
    $form.Controls.Add($txtFeed)

    $lblFeedNote = New-Object System.Windows.Forms.Label
    $lblFeedNote.Text = "mm/min or in/min depending on your LinuxCNC units"
    $lblFeedNote.Location = [System.Drawing.Point]::new(16, 42)
    $lblFeedNote.Size = [System.Drawing.Size]::new(470, 18)
    $lblFeedNote.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($lblFeedNote)

    # --- Hardware type ---
    $lblHw = New-Object System.Windows.Forms.Label
    $lblHw.Text = "Output hardware:"
    $lblHw.Location = [System.Drawing.Point]::new(16, 74)
    $lblHw.Size = [System.Drawing.Size]::new(200, 22)
    $lblHw.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $form.Controls.Add($lblHw)

    $cmbHw = New-Object System.Windows.Forms.ComboBox
    $cmbHw.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbHw.Location = [System.Drawing.Point]::new(16, 98)
    $cmbHw.Size = [System.Drawing.Size]::new(470, 28)
    [void]$cmbHw.Items.Add("Mesa FPGA card (7i76e, 7i96, 5i25, etc.)")
    [void]$cmbHw.Items.Add("Parallel port (DB25 directly wired)")
    $cmbHw.SelectedIndex = 0
    $form.Controls.Add($cmbHw)

    # --- Info label ---
    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = @"
The exported file will have the correct gain value pre-calculated
and the appropriate pin assignments uncommented for your hardware.

Copy the file to your LinuxCNC config directory:
  ~/linuxcnc/configs/[your-machine]/

Then add to your HAL:
  source steelmettle_thc_feedrate.hal
"@
    $lblInfo.Location = [System.Drawing.Point]::new(16, 138)
    $lblInfo.Size = [System.Drawing.Size]::new(470, 110)
    $form.Controls.Add($lblInfo)

    # --- Destination ---
    $lblDest = New-Object System.Windows.Forms.Label
    $lblDest.Text = "Export to:"
    $lblDest.Location = [System.Drawing.Point]::new(16, 256)
    $lblDest.Size = [System.Drawing.Size]::new(80, 22)
    $lblDest.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $form.Controls.Add($lblDest)

    $txtDest = New-Object System.Windows.Forms.TextBox
    $txtDest.Location = [System.Drawing.Point]::new(100, 254)
    $txtDest.Size = [System.Drawing.Size]::new(320, 24)
    $txtDest.Text = [Environment]::GetFolderPath("Desktop")
    $form.Controls.Add($txtDest)

    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Text = "..."
    $btnBrowse.Location = [System.Drawing.Point]::new(426, 253)
    $btnBrowse.Size = [System.Drawing.Size]::new(60, 26)
    $btnBrowse.FlatStyle = "Flat"
    $btnBrowse.Add_Click({
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "Select destination folder (USB drive, network share, etc.)"
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtDest.Text = $fbd.SelectedPath
        }
        $fbd.Dispose()
    })
    $form.Controls.Add($btnBrowse)

    # --- Buttons ---
    $btnExport = New-Object System.Windows.Forms.Button
    $btnExport.Text = "Export"
    $btnExport.Location = [System.Drawing.Point]::new(298, 304)
    $btnExport.Size = [System.Drawing.Size]::new(90, 32)
    $btnExport.BackColor = $accentColor
    $btnExport.ForeColor = $textColor
    $btnExport.FlatStyle = "Flat"
    $btnExport.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $btnExport
    $form.Controls.Add($btnExport)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = [System.Drawing.Point]::new(396, 304)
    $btnCancel.Size = [System.Drawing.Size]::new(90, 32)
    $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(122, 58, 34)
    $btnCancel.ForeColor = $textColor
    $btnCancel.FlatStyle = "Flat"
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $btnCancel
    $form.Controls.Add($btnCancel)

    $dialogResult = $form.ShowDialog()
    $feedVal = $txtFeed.Text
    $hwIndex = $cmbHw.SelectedIndex
    $destVal = $txtDest.Text
    $form.Dispose()

    if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    # Validate feedrate is a positive number
    $maxFeed = 0.0
    if (-not [double]::TryParse($feedVal, [ref]$maxFeed) -or $maxFeed -le 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Invalid max feedrate value: $feedVal`n`nPlease enter a positive number (e.g., 500).",
            "STEELMETTLE THC: Invalid Input",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return $null
    }

    return @{
        MaxFeedrate = $maxFeed
        HardwareType = if ($hwIndex -eq 0) { "mesa" } else { "parport" }
        DestinationFolder = $destVal
    }
}

function Export-LinuxCNCFeedrateBus {
    <#
    .SYNOPSIS
    Main function: Show config dialog, customize HAL template, export to destination

    .OUTPUTS
    @{ Success = $true; Message = "..."; ExportPath = "..." } or failure object
    #>

    Add-Type -AssemblyName System.Windows.Forms

    # Step 1: Show configuration dialog
    $config = New-LinuxCNCExportDialog
    if (-not $config) {
        return @{ Success = $false; Message = "User cancelled export" }
    }

    # Step 2: Find source HAL template
    $sourceFileName = "LINUXCNC_FEEDRATE_THC.hal"
    $integrationDir = if ($baseDir) { $baseDir } elseif ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $sourceFile = Join-Path (Join-Path $integrationDir "PoKeys") $sourceFileName

    if (-not (Test-Path $sourceFile)) {
        [System.Windows.Forms.MessageBox]::Show(
            "LinuxCNC HAL template not found:`n`n$sourceFile`n`nThe STEELMETTLE integrator may be incomplete.",
            "STEELMETTLE THC: Template Missing",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return @{ Success = $false; Message = "LinuxCNC HAL template not found" }
    }

    # Step 3: Read template and customize
    $halContent = [System.IO.File]::ReadAllText($sourceFile, [System.Text.Encoding]::UTF8)

    # Calculate gain: 255 / (max_feed_per_minute / 60)
    $maxFeedPerSec = $config.MaxFeedrate / 60.0
    $gain = [Math]::Round(255.0 / $maxFeedPerSec, 3)

    # Replace the gain placeholder
    # The template has: setp scale.0.gain  30.6  (or similar default)
    $halContent = $halContent -replace '(setp\s+scale\.0\.gain\s+)\S+', "`${1}$gain"

    # Uncomment the correct hardware section and comment out the other
    if ($config.HardwareType -eq "mesa") {
        # Uncomment Mesa lines (remove leading # from Mesa net lines)
        $halContent = $halContent -replace '(?m)^#\s*(net\s+thc-fd-bit\d+\s.*hm2_)', '$1'
        $halContent = $halContent -replace '(?m)^#\s*(net\s+thc-fd-strobe\s.*hm2_)', '$1'
        # Keep parport lines commented (they should already be)
    } else {
        # Uncomment parport lines (remove leading # from parport net lines)
        $halContent = $halContent -replace '(?m)^#\s*(net\s+thc-fd-bit\d+\s.*parport)', '$1'
        $halContent = $halContent -replace '(?m)^#\s*(net\s+thc-fd-strobe\s.*parport)', '$1'
        # Keep Mesa lines commented (they should already be)
    }

    # Add a header comment with the user's configuration
    $configHeader = @"
# =============================================================================
# AUTO-CONFIGURED by STEELMETTLE THC Systems Integrator
# Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Max feedrate: $($config.MaxFeedrate) units/min ($([Math]::Round($maxFeedPerSec, 4)) units/sec)
# Gain: $gain (= 255 / $([Math]::Round($maxFeedPerSec, 4)))
# Hardware: $($config.HardwareType)
# =============================================================================

"@
    $halContent = $configHeader + $halContent

    # Step 4: Validate destination
    $destFolder = $config.DestinationFolder
    if (-not (Test-Path $destFolder)) {
        try {
            New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Cannot create destination folder:`n`n$destFolder`n`n$_",
                "STEELMETTLE THC: Export Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            return @{ Success = $false; Message = "Cannot create destination folder: $_" }
        }
    }

    # Step 5: Write customized HAL file
    $destFile = Join-Path $destFolder "steelmettle_thc_feedrate.hal"

    try {
        # Write as UTF-8 without BOM (Linux-friendly)
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($destFile, $halContent, $utf8NoBom)

        if ($null -ne $logDir) {
            $logMsg = "Exported LinuxCNC HAL: $destFile (gain=$gain, hw=$($config.HardwareType))"
            (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + " $logMsg" | Add-Content (Join-Path $logDir 'integrator.log') -Encoding ASCII
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to write HAL file:`n`n$_",
            "STEELMETTLE THC: Export Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return @{ Success = $false; Message = "Failed to write HAL file: $_" }
    }

    # Step 6: Also copy the Centroid reference file if present
    $centroidSource = Join-Path (Join-Path $integrationDir "PoKeys") "CENTROID_FEEDRATE_THC_REFERENCE.txt"
    if (Test-Path $centroidSource) {
        # Just a bonus copy; don't fail if this doesn't work
        try {
            Copy-Item -Path $centroidSource -Destination (Join-Path $destFolder "CENTROID_FEEDRATE_THC_REFERENCE.txt") -Force -ErrorAction SilentlyContinue
        } catch { }
    }

    # Step 7: Show success
    $instructions = @"
LINUXCNC HAL CONFIGURATION EXPORTED

File: $destFile

Configuration:
  Max feedrate: $($config.MaxFeedrate) units/min
  Gain value: $gain
  Hardware: $(if ($config.HardwareType -eq 'mesa') { 'Mesa FPGA card' } else { 'Parallel port' })

NEXT STEPS:
  1. Copy steelmettle_thc_feedrate.hal to your LinuxCNC
     machine config directory:
     ~/linuxcnc/configs/[your-machine]/

  2. Add to your main HAL or custom_postgui.hal:
     source steelmettle_thc_feedrate.hal

  3. Edit the pin assignments in the file to match
     your specific $(if ($config.HardwareType -eq 'mesa') { 'Mesa card GPIO' } else { 'parallel port' }) wiring

  4. Run halcmd show pin thc to verify signals
"@

    [System.Windows.Forms.MessageBox]::Show(
        $instructions,
        "STEELMETTLE THC: LinuxCNC HAL Exported",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null

    return @{
        Success = $true
        Message = "LinuxCNC HAL exported successfully"
        ExportPath = $destFile
        Gain = $gain
        HardwareType = $config.HardwareType
    }
}

if ($null -ne $ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function @(
        'Export-LinuxCNCFeedrateBus'
    )
}
