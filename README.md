# Docker-OSX AU Testing

macOS in Docker for Windows AU plugin testing on Windows via WSL2.

## Current Status

| Feature | Status | Notes |
|---------|--------|-------|
| VNC access | ✅ Works | Port 5999 |
| macOS boot | ✅ Works | Without audio devices |
| SSH access | ✅ Works | After setup |
| File transfer | ✅ Works | VirtioFS + SCP |
| **Audio output** | ❌ **Broken** | WSL2 limitation |
| AU validation | ✅ Partial | pluginval API tests work |

## Quick Start

```bash
# Start container
docker-compose up -d

# Connect via VNC to localhost:5999
# Or connect via SSH: ssh -p 50922 arch@localhost
```

## Backup & Restore

**IMPORTANT:** Your macOS installation lives in the `macos-disk` Docker volume. Always backup before major changes!

### Create Backup
```bash
./backup-macos.sh
```
- Creates timestamped backup in `./backups/`
- Stops container temporarily during backup
- Takes 10-30 minutes for 31GB data

### Restore from Backup
```bash
./restore-macos.sh ./backups/macos-backup-YYYYMMDD_HHMMSS.tar.gz
```
- **WARNING:** Replaces current installation completely
- Stops container, removes old volume, restores backup

### Current Images
- `macos12.7.4:init` - Base macOS installation (docker commit)
- `./backups/` - Full volume backups (includes all data)

## Persistence Strategy

### Named Volumes (bind to local `./data/`)
| Volume | Container Path | Local Path | Purpose |
|--------|---------------|------------|---------|
| `macos-disk` | `/home/arch/OSX-KVM` | Docker managed | macOS disk image |
| `xcode-cache` | `/home/arch/xcode-cache` | `./data/xcode-cache` | Xcode CLI tools (5GB) |
| `build-cache` | `/home/arch/build-cache` | `./data/build-cache` | CMake/JUCE build cache |
| `ssh-keys` | `/home/arch/.ssh` | `./data/ssh-keys` | SSH keys |
| `homebrew-cache` | `/home/arch/Library/Caches/Homebrew` | `./data/homebrew-cache` | Homebrew cache |

### Bind Mounts (VirtioFS - Live sync with Windows)
| Windows Path | Container Path | Mode | Purpose |
|-------------|---------------|------|---------|
| `/mnt/c/dev/HeathAudio` | `/host-source` | read-only | Source code |
| `/mnt/c/dev/HeathAudio/build` | `/host-build` | read-write | Build outputs |

## Next Steps

1. ✅ macOS installed (Monterey 12.7.4)
2. Enable SSH: `sudo systemsetup -setremotelogin on`
3. Install Homebrew, pluginval
4. Test AU validation (API tests don't need audio)
5. Document file-based audio testing workflow

## Audio Limitation

Audio is fundamentally broken on WSL2/Docker Desktop for Windows:
- ❌ PulseAudio via WSLg does not work
- ❌ Intel HDA devices are not detected in macOS
- ❌ USB audio passthrough is blocked by Windows device binding
- ❌ dockurr/macos requires KVM (not available on Windows Docker Desktop)

**Workaround:** Use file-based audio testing - export audio files from macOS and play on Windows.
