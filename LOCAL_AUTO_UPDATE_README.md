# Local Workspace Auto-Update System

## Overview
Your app now automatically detects and applies changes from your workspace folder. No GitHub pushing required—just save files in your workspace and the installed app will sync them automatically.

## How It Works

### Update Flow
1. **File Detection**: When you save changes to files in `c:\Users\jashu\OneDrive\Documents\STEELMETTLE-THC-Systems-Integrator`, the system detects them
2. **Auto-Sync**: On app startup (or when checking for updates), the system compares workspace file timestamps against the installed app copies
3. **Copy & Restart**: If workspace files are newer, they're copied to the installed app location, then the app restarts to apply changes
4. **No Manual Steps**: Everything happens automatically—no pushing to GitHub, no manual installer runs

### Key Configuration
The `config.json` now uses:
```json
"update": {
  "enabled": true,
  "mode": "local-workspace",
  "workspaceDir": ".",
  "autoCheckOnLaunch": true,
  "autoSync": true,
  "checkIntervalSeconds": 30
}
```

**Settings:**
- `mode`: Set to `local-workspace` (instead of GitHub)
- `workspaceDir`: Path to workspace (`.` means current folder, where config.json is)
- `autoCheckOnLaunch`: Checks for updates when you start the app
- `autoSync`: Automatically copies changed files without prompting
- `checkIntervalSeconds`: How often to check (30 seconds between checks)

## Files That Auto-Sync
When workspace versions are newer, these files/folders are automatically copied:
- `config.json` - Settings
- `STEELMETTLE-THC-Systems-Integrator.ps1` - Main script
- `MachMacroInstaller.ps1` - Macro helpers
- `assets/` - Background images and resources
- `licenses/` - License files

## Workflow Example

**Scenario**: You edit a configuration setting in `config.json`

1. You save `c:\Users\jashu\OneDrive\Documents\STEELMETTLE-THC-Systems-Integrator\config.json`
2. You start/restart the app
3. App detects workspace `config.json` is newer (newer modification timestamp)
4. App automatically copies the workspace config to the installed location
5. App restarts to load the new configuration
6. **Your change is now live** ✓

## Development Workflow

**For making changes:**
1. Edit files in your workspace folder (where they currently are)
2. Save changes
3. Restart the app (or wait for next auto-check)
4. Changes apply automatically

**Example changes:**
- Edit `STEELMETTLE-THC-Systems-Integrator.ps1` → restart app → new version runs
- Edit `config.json` → app restarts → new config loaded
- Add/update background image in `assets/` → restart app → new image displays

## System Locations

- **Workspace** (your source): `c:\Users\jashu\OneDrive\Documents\STEELMETTLE-THC-Systems-Integrator`
- **Installed app** (running copy): `c:\Users\jashu\AppData\Local\STEELMETTLE THC Systems Integrator`

The system syncs from workspace → installed app automatically.

## Advanced: Manual Check

You can force an update check from the app UI:
- Look for an "Update" or "Check for Updates" button
- Click it to manually trigger the workspace sync

## GitHub Separation

- **Workspace folder**: For local development (auto-syncs to your installation)
- **GitHub repo**: Separate (for public releases/sharing only, not linked to local updates)
- **Result**: You can develop locally without any GitHub interaction

## Fallback to GitHub Mode

If you need to revert to GitHub-based updates, change config `"mode"` back to `"github"` (requires `repo` and `assetNamePattern` to be set).

## Troubleshooting

**Changes not applying?**
- Make sure `update.enabled` is `true` in config.json
- Check that `update.mode` is `"local-workspace"`
- Restart the app (check triggers on startup)
- Verify workspace path exists and is accessible

**App not restarting after sync?**
- If `autoSync` is `false`, the app will alert you but not restart
- Change to `"autoSync": true` to auto-restart

**Need to manually sync?**
- Copy changed files directly from workspace to `c:\Users\jashu\AppData\Local\STEELMETTLE THC Systems Integrator`
- Restart app

---

**Version**: 1.0.25  
**When configured**: April 2, 2026  
**Last updated workspace files**: Automatically sync from `.\STEELMETTLE-THC-Systems-Integrator\config.json`
