# Docker-OSX Audio Setup Guide

## Overview

This guide explains how to enable Core Audio output from the macOS Docker container to Windows host speakers via PulseAudio on WSL2/WSLg.

**Target Use Case:** Audio output verification for Logic Pro AU plugin testing.

---

## Architecture

```
macOS Container (QEMU) → Intel HDA Device → PulseAudio → WSLg → Windows Audio
```

1. **QEMU Intel HDA**: Virtual audio device in macOS container
2. **PulseAudio Backend**: Routes audio to host via Unix socket
3. **WSLg Integration**: Windows 11's WSLg includes PulseAudio server

---

## Quick Start (WSLg)

### Prerequisites
- Windows 11 with WSLg enabled
- Docker Desktop or Docker Engine running on WSL2

### Step 1: Verify WSLg PulseAudio Socket

```bash
# In WSL2 terminal
ls -la /mnt/wslg/runtime-dir/pulse/native
```

Expected output: Socket file exists

### Step 2: Update docker-compose.yml

The docker-compose.yml is already configured with WSLg PulseAudio:

```yaml
environment:
  - AUDIO_DRIVER=pa,server=unix:/tmp/pulseaudio.socket
  - EXTRA=-display none -vnc 0.0.0.0:99 -device intel-hda -device hda-duplex
volumes:
  - /mnt/wslg/runtime-dir/pulse/native:/tmp/pulseaudio.socket
```

### Step 3: Start Container

```bash
cd macos-docker-au
docker-compose down
docker-compose up -d

# Wait for macOS boot (60-90 seconds)
sleep 60
```

### Step 4: Test Audio Output

```bash
# SSH into macOS container
ssh -p 50922 user@localhost

# Test system sound
afplay /System/Library/Sounds/Glass.aiff
```

**Expected Result:** Sound plays from Windows host speakers.

---

## Fallback: Traditional PulseAudio Setup

If WSLg socket is unavailable, install PulseAudio in WSL2.

### Step 1: Run Setup Script

```bash
cd macos-docker-au
source setup-audio-wslg.sh
```

### Step 2: Update docker-compose.yml

Change the volume mount:

```yaml
volumes:
  - /run/user/1000/pulse/native:/tmp/pulseaudio.socket
```

### Step 3: Restart Container

```bash
docker-compose down
docker-compose up -d
```

---

## macOS Audio Configuration

### Verify Core Audio Devices

```bash
# SSH into macOS
ssh -p 50922 user@localhost

# Check audio hardware
system_profiler SPAudioDataType

# Check for AppleHDAController
kextstat | grep Apple
# Should see: com.apple.driver.AppleHDAController
```

### Audio MIDI Setup

```bash
# Open Audio MIDI Setup GUI
open -a "Audio MIDI Setup"
```

In VNC viewer (localhost:5999), verify "Built-in Output" is available.

---

## Logic Pro Audio Testing

### Configure Audio Output

1. Open Logic Pro (via VNC)
2. **Logic Pro → Preferences → Audio**
3. **Output Device:** Select "Built-in Output"

### Test Plugin Audio

1. Load AmpBender AU plugin
2. Play test tone or audio
3. Verify output on Windows host speakers

---

## Troubleshooting

### Issue: No WSLg PulseAudio Socket

**Symptom:** `ls: cannot access '/mnt/wslg/runtime-dir/pulse/native': No such file or directory`

**Solutions:**
1. Ensure Windows 11 with WSLg is installed
2. Run `wsl --update` to update WSL
3. Use fallback setup script: `source setup-audio-wslg.sh`

### Issue: No Audio Devices in macOS

**Symptom:** `system_profiler SPAudioDataType` shows no devices

**Check 1:** Verify EXTRA parameter includes HDA devices
```bash
docker exec macos-au-tester env | grep EXTRA
# Should include: -device intel-hda -device hda-duplex
```

**Check 2:** Verify QEMU devices
```bash
docker logs macos-au-tester | grep -i hda
```

### Issue: Audio Device Visible but No Sound

**Symptom:** "Built-in Output" exists but no audio on host

**Check 1:** Verify macOS output device
```bash
defaults read com.apple.sound
```

**Check 2:** Test with system sound
```bash
afplay /System/Library/Sounds/Glass.aiff
```

**Check 3:** Check PulseAudio on WSL2 host
```bash
pactl info
pactl list sinks
```

### Issue: PulseAudio Socket Permission Denied

**Symptom:** Container cannot access socket

**Fix:** Ensure container has proper permissions:
```bash
docker exec macos-au-tester ls -la /tmp/pulseaudio.socket
```

If permissions are wrong, adjust socket permissions on host:
```bash
sudo chmod 666 /mnt/wslg/runtime-dir/pulse/native
# or
sudo chmod 666 /run/user/1000/pulse/native
```

---

## Verification Checklist

- [ ] WSLg PulseAudio socket exists at `/mnt/wslg/runtime-dir/pulse/native`
- [ ] docker-compose.yml includes `AUDIO_DRIVER=pa,server=unix:/tmp/pulseaudio.socket`
- [ ] docker-compose.yml includes `-device intel-hda -device hda-duplex` in EXTRA
- [ ] Container starts successfully
- [ ] SSH into macOS works
- [ ] `system_profiler SPAudioDataType` shows audio devices
- [ ] `afplay /System/Library/Sounds/Glass.aiff` produces sound on Windows host
- [ ] Logic Pro can select "Built-in Output"
- [ ] Plugin audio output works

---

## Advanced: USB Audio Interface Passthrough (Future)

If built-in audio quality is insufficient, USB audio interface passthrough is available as a future enhancement.

**Requirements:**
1. Windows: Install [usbipd-win](https://github.com/dorssel/usbipd-win)
2. WSL2: Attach USB device on each restart
3. Docker-OSX: Additional `usb-host` device configuration

**Note:** USB passthrough is not persistent across WSL restarts and requires manual reattachment.

---

## References

- [sickcodes/Docker-OSX GitHub](https://github.com/sickcodes/Docker-OSX)
- [Docker-OSX PulseAudio Configuration](https://github.com/sickcodes/Docker-OSX#pulseaudio)
- [WSL USB Device Documentation](https://devblogs.microsoft.com/commandline/connecting-usb-devices-to-wsl/)
