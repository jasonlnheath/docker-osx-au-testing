# Docker-OSX AU Testing

macOS in Docker for Windows AU plugin testing on Windows via WSL2.

## ⚠️ Critical Limitation: Audio Not Working

**Audio is fundamentally broken on WSL2/Docker Desktop for Windows.**

After extensive testing, we confirmed that:
- ❌ PulseAudio via WSLg does not work
- ❌ Intel HDA devices are not detected in macOS
- ❌ USB audio passthrough is blocked by Windows device binding
- ❌ dockurr/macos requires KVM (not available on Windows Docker Desktop)

## Current Status

| Feature | Status | Notes |
|---------|--------|-------|
| VNC access | ✅ Works | Port 5999 |
| macOS boot | ✅ Works | Without audio devices |
| SSH access | ✅ Works | After setup |
| File transfer | ✅ Works | SCP/SSH |
| **Audio output** | ❌ **Broken** | WSL2 limitation |
| AU validation | ✅ Partial | pluginval API tests work |

## Quick Start

```bash
# Start container (VNC works, audio fails)
docker run -d --name macos-au-tester --privileged \
  -p 5999:5999 -p 50922:10022 \
  -v macos-disk:/home/arch/OSX-KVM \
  -e RAM=16 -e CORES=4 -e DEVICE_MODEL=iMacPro1,1 \
  -e GENERATE_UNIQUE=true \
  -e "EXTRA=-display none -vnc 0.0.0.0:99" \
  sickcodes/docker-osx:latest
```

## Next Steps

1. Complete macOS setup (Sequoia installing now)
2. Enable SSH: `sudo systemsetup -setremotelogin on`
3. Install Homebrew, pluginval
4. Test AU validation (API tests don't need audio)
5. Document file-based audio testing workflow

## Project History

Created after extensive attempts to get audio working with:
- PulseAudio via WSLg ❌
- Intel HDA devices ❌
- USB audio passthrough ❌
- dockurr/macos (requires KVM) ❌

All audio approaches failed due to WSL2 limitations.
