# Firmware Sync & Update Module

## Overview

The **Firmware Sync Module** automatically monitors your firmware source repositories (STM32MX_V3.0.1 and Arduino/THC_AUTOSET_Firmware) and checks GitHub for upstream updates. This ensures the STEELMETTLE integrator app always has the latest firmware to flash to devices.

## Features

Ã¢Å“â€¦ **Local File Monitoring** Ã¢â‚¬â€ Detects changes in STM32MX_V3.0.1 and Arduino/THC_AUTOSET_Firmware folders
Ã¢Å“â€¦ **Auto-Sync** Ã¢â‚¬â€ Copies changed firmware files to integrator working folders
Ã¢Å“â€¦ **GitHub Integration** Ã¢â‚¬â€ Checks for new commits on GitHub repos
Ã¢Å“â€¦ **File Hash Tracking** Ã¢â‚¬â€ Remembers which files have changed (logs/file_hashes.json)
Ã¢Å“â€¦ **Multiple Modes** Ã¢â‚¬â€ Monitor once, continuous watch, force sync, or GitHub-only check
Ã¢Å“â€¦ **Scheduled Task Support** Ã¢â‚¬â€ Can run as Windows scheduled task for background monitoring

## Usage

### Quick Check (Default)
```bash
firmware-sync.bat
# or
firmware-sync.bat monitor
```
Checks for local changes once and syncs any modified files.

### GitHub Update Check
```bash
firmware-sync.bat github
```
Queries GitHub repos for latest commits and shows available versions.

### Force Full Sync
```bash
firmware-sync.bat sync
```
Copies all source files to integrator folders (useful after fresh clone).

### Continuous Watch (Background)
```bash
firmware-sync.bat watch
```
Continuously monitors firmware source folders every 60 seconds. **Ctrl+C to stop.**

## Configuration (config.json)

### Firmware Update Settings
```json
"firmwareUpdate": {
  "checkOnConnect": true,
  "checkOnLaunch": true,
  "autoSync": true,
  "forge": {
    "enabled": true,
    "repo": "STEELMETTLE-LLC/STEELMETTLE-THC-Forge-Firmware",
    "branch": "main",
    "sourceDir": "..\\STM32MX_V3.0.1",
    "currentVersion": "3.0.2"
  },
  "core": {
    "enabled": true,
    "repo": "STEELMETTLE-LLC/THC-AUTOSET-Firmware",
    "branch": "main",
    "sourceDir": "..\\Arduino\\THC_AUTOSET_Firmware",
    "currentVersion": "1.0.1"
  }
}
```

**Key Settings:**
- `enabled`: Set to `true` to monitor this firmware repo
- `repo`: GitHub repo in format `owner/repo`
- `branch`: Branch to monitor (typically `main` or `master`)
- `sourceDir`: Local source folder path (relative to integrator root)
- `currentVersion`: Used to track version changes

### File Monitoring Settings
```json
"fileMonitoring": {
  "enabled": true,
  "checkIntervalSeconds": 60,
  "watchFiles": [
    {
      "label": "STM32 Firmware",
      "sourceDir": "..\\STM32MX_V3.0.1",
      "targetDir": "STM32",
      "patterns": ["Core/Src/**/*.c", "Core/Inc/**/*.h"],
      "syncOnChange": true
    }
  ]
}
```

**Key Settings:**
- `label`: Human-readable name for this watch
- `sourceDir`: Where to look for changes (relative to integrator)
- `targetDir`: Where to copy files when they change (relative to integrator)
- `patterns`: Glob patterns for which files to monitor
- `syncOnChange`: If `true`, automatically copy to targetDir when files change

## File Hash Log

The module maintains `logs/file_hashes.json` to track which files have changed since the last check:

```json
{
  "STM32 Firmware/Core/Src/gpio.c": "a1b2c3d4...",
  "STM32 Firmware/Core/Inc/main.h": "e5f6g7h8...",
  "Arduino Firmware/ThcControl.cpp": "i9j0k1l2..."
}
```

This file is automatically updated on each run.

## Setup as Windows Scheduled Task (Optional)

To run sync checks automatically every hour in the background:

### 1. Open Task Scheduler
```
Windows Key Ã¢â€ â€™ "Task Scheduler" Ã¢â€ â€™ Open
```

### 2. Create New Task
- **Name:** `STEELMETTLE Firmware Sync`
- **Description:** `Check for firmware updates and sync changes`
- **Run with highest privileges:** Ã¢Å“â€œ (checkmark)

### 3. Trigger
- **New Trigger** Ã¢â€ â€™ At startup (or every 1 hour)
- **Delay task:** 30 seconds (to avoid startup conflicts)

### 4. Action
- **Action:** Start a program
- **Program/script:** `C:\Windows\System32\cmd.exe`
- **Arguments:** `/c D:\path\to\integrator\firmware-sync.bat monitor >> D:\path\to\integrator\logs\sync.log 2>&1`

### 5. Settings
- **Run whether user is logged in or not:** Checked
- **Stop if still running after:** 10 minutes
- **Hidden:** Checked (so it doesn't pop up windows)

## Output & Logs

### Console Output
```
Ã°Å¸â€œÂ Monitoring local firmware changes...
  Checking: STM32 Firmware
    Ã¢Å“ÂÃ¯Â¸Â  Modified: Core/Src/gpio.c
    Ã¢Å“ÂÃ¯Â¸Â  Modified: Core/Inc/main.h

Ã¢Å“â€¦ Found 2 changed file(s)

Ã°Å¸â€œÂ¤ Syncing changed files to integrator folders...
  Ã¢Å“â€œ Synced: Core/Src/gpio.c
  Ã¢Å“â€œ Synced: Core/Inc/main.h

Ã¢Å“â€œ Sync complete - firmware is up to date
```

### GitHub Check Output
```
Ã°Å¸â€â€” Checking GitHub for firmware updates...

[STM32 Forge Firmware]
  Checking GitHub: STEELMETTLE-LLC/STEELMETTLE-THC-Forge-Firmware/main
    Latest: a1b2c3d (2026-03-16T10:30:00Z)
    Message: Update GPIO initialization for new IDC grouping

  Current version: 3.0.2
  Latest commit: a1b2c3d

[Arduino Core Firmware]
  Checking GitHub: STEELMETTLE-LLC/THC-AUTOSET-Firmware/main
    Latest: e5f6g7h (2026-03-16T09:15:00Z)
    Message: Fix PoExtension strobe timing

  Current version: 1.0.1
  Latest commit: e5f6g7h

Ã¢Å“â€¦ Found 2 firmware repository(ies) to track
```

## Integration with Main App

The main `STEELMETTLE-THC-Systems-Integrator.ps1` script can call the sync module on launch:

```powershell
# Before flashing, check for updates
.\firmware-sync.ps1 -Mode monitor -Config config.json

# Offer user the option to download latest from GitHub
$githubCheck = .\firmware-sync.ps1 -Mode github
```

## GitHub API Rate Limiting

The module respects GitHub's public API rate limits (60 requests per minute without auth). If you hit limits:

1. **Add GitHub token** to `config.json`:
   ```json
   "github": {
     "token": "ghp_your_github_token_here",
     "rateLimit": 5000
   }
   ```

2. **Use authenticated requests** (not yet implemented, but token is ready)

## Troubleshooting

### "Source directory not found"
- **Check:** Is STM32MX_V3.0.1 or Arduino/THC_AUTOSET_Firmware in the parent directory?
- **Fix:** Update `sourceDir` paths in `config.json` to match your folder structure

### Files not syncing
- **Check:** Is `syncOnChange` set to `true` in the watch config?
- **Check:** Are the `patterns` correct? (glob format: `path/**/*.extension`)
- **Fix:** Run `firmware-sync.bat sync` to force-sync all files

### GitHub check fails ("Could not check GitHub")
- **Check:** Internet connection is working
- **Check:** GitHub repo names are correct (`owner/repo`)
- **Check:** Repo is public (or use token for private repos)

## Next Steps

1. **Add GitHub repos** to `config.json` with your actual GitHub usernames/repos
2. **Test the sync** with `firmware-sync.bat monitor`
3. **Set up scheduled task** if you want automatic background checks
4. **Integrate with main app** to offer firmware updates when users connect devices

---

**Questions?** See `config.json` documentation or check `logs/file_hashes.json` to verify what was tracked.
