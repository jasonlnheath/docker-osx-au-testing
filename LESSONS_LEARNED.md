# Lessons Learned: Docker-OSX Audio on Windows

## The Problem

We wanted to test Audio Unit (AU) plugins on macOS from Windows without owning Mac hardware. Docker-OSX seemed perfect - run macOS in a container via QEMU.

**The fatal issue: Audio doesn't work.**

## What We Tried

### 1. PulseAudio via WSLg (Windows 11)

**Attempt:** Mount `/mnt/wslg/PulseServer` and set `PULSE_SERVER` environment variable.

**Result:** Socket is accessible, but no audio output to Windows speakers.

**Why:** WSLg PulseAudio server doesn't actually route audio to Windows for non-WSLg applications. The socket exists but audio goes nowhere.

### 2. Intel HDA Devices

**Attempt:** Add `-device intel-hda -device hda-duplex` to QEMU command.

**Result:** Error: "no default audio driver available"

**Why:** sickcodes/docker-osx doesn't include audio codec drivers in OpenCore configuration. The HDA device exists but macOS has no driver for it.

### 3. USB Audio Passthrough

**Attempt:** Use usbipd-win to share Audient iD14 interface (2708:0002) with WSL2.

**Result:** USB devices persistently bound to Windows, cannot be detached.

**Why:** Windows claims USB audio devices at boot and won't release them. usbipd-win requires devices to be unbound first, but Windows holds onto audio interfaces.

### 4. dockurr/macos Alternative

**Attempt:** Switch to dockurr/macos which has built-in `AUDIO_OUTPUT`/`AUDIO_INPUT` environment variables.

**Result:** Container won't start - requires `/dev/kvm`

**Why:** KVM (Kernel-based Virtual Machine) is a Linux kernel feature. WSL2 doesn't expose `/dev/kvm` to containers. Windows 11 has nested virtualization but it's Hyper-V based, not KVM.

## Root Cause Analysis

### Why WSL2 Audio Doesn't Work

1. **WSLg PulseAudio limitation**: The PulseAudio socket at `/mnt/wslg/PulseServer` exists for Wayland applications, but QEMU running in Docker can't use it for audio routing.

2. **No ALSA devices**: Docker containers on Windows don't have `/dev/snd/*` devices. ALSA (Advanced Linux Sound Architecture) requires these devices.

3. **KVM not available**: `/dev/kvm` doesn't exist in WSL2. This is a hard requirement for dockurr/macos and would provide better audio options.

### What Would Work

1. **Real Mac hardware** - Obviously
2. **macOS VM** - VMware Fusion or Parallels on macOS host
3. **Linux host** - Run Docker-OSX on Linux with proper KVM and ALSA
4. **Cloud macOS** - MacStadium, AWS EC2 Mac instances

## What This Setup Is Good For

Despite no audio, this setup IS useful for:

- ✅ **pluginval API validation** - Tests plugin loading, parameters, basic processing
- ✅ **Visual testing** - VNC access shows plugin UI correctly
- ✅ **Parameter automation** - Verify parameters change and persist
- ✅ **Build verification** - Confirm AU compiles and loads on macOS
- ✅ **File-based testing** - Export audio files, play on Windows

## What This Setup Cannot Do

- ❌ Real-time audio monitoring
- ❌ Audio quality validation  
- ❌ DSP algorithm verification
- ❌ Latency measurements
- ❌ DAW workflow testing with audio

## Conclusion

Docker-OSX on Windows is valuable for **API-level testing** but **not suitable for audio validation**.

For proper AU testing with audio, you need:
1. Real Mac hardware, OR
2. macOS VM with working audio passthrough, OR
3. Cloud macOS instance

**Accept this limitation and focus on what works.**
