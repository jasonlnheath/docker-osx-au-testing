---
description: List and restore macOS Docker container backups
---

# macOS Restore Skill

Lists all available backups and allows restoring a selected backup.

## What this skill does

1. Reads metadata from `./backups/backups.json`
2. Displays all backups with: name, description, timestamp, filename, and size
3. Checks if the container is running
4. Prompts user to select a backup by ID or name
5. Confirms the restore operation
6. Stops container
7. Removes old volume
8. Creates new volume
9. Restores selected backup
10. Starts container
11. Displays success message

## Usage

Run `/macos-restore` to see available backups and restore one.

## Backup List Format

```
Available Backups:
------------------
[1] Initial macOS setup
    Description: Monterey 12.7.4 with basic configuration
    Created: 2025-01-26 16:30:00
    File: macos-backup-20250126_163000.tar.gz
    Size: 31.2 GB

[2] After Xcode install
    Description: Fresh Xcode 15.4 installation
    Created: 2025-01-27 10:15:00
    File: macos-backup-20250127_101500.tar.gz
    Size: 42.8 GB
```

## Implementation

1. Read `./backups/backups.json`
2. Parse and display available backups
3. Prompt user to select backup
4. Confirm restore operation
5. Run: `./restore-macos.sh <backup-file>` from selected backup metadata
