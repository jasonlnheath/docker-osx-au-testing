# USB Audio Passthrough - Next Steps

## Current Status

**Completed:**
- ✅ Docker-OSX PulseAudio configuration added
- ✅ WSLg directory mount configured
- ✅ Container boots successfully
- ✅ usbipd-win installed (v5.3.0) at `C:\Program Files\usbipd-win\usbipd.exe`

**Issue:**
- ❌ macOS cannot detect HDA audio device (missing codec driver)
- ❌ USB audio device passthrough in progress

---

## USB Devices Found

| BUSID | VID:PID | Device | Status |
|-------|---------|--------|--------|
| 10-1 | 2708:0002 | Audient iD14 | In use by Windows |
| 10-2 | ??? | USB audio device | In use by Windows |

---

## Next Steps to Complete USB Audio Passthrough

### Step 1: Free USB Device from Windows

**Option A: Change Windows Default Audio Device**
1. Right-click speaker icon → "Open Sound settings"
2. Change output device to something else (e.g., Realtek speakers)
3. Change input device to something else
4. Wait 5 seconds for Windows to release device

**Option B: Disable Device in Device Manager**
1. Right-click Start → Device Manager
2. Expand "Sound, video and game controllers"
3. Right-click the USB audio device → "Disable device"
4. Confirm disable

### Step 2: Attach USB Device to WSL2

```powershell
& "C:\Program Files\usbipd-win\usbipd.exe" attach --wsl --busid 10-2
```

Expected output:
```
usbipd: info: Using WSL distribution 'Ubuntu' to attach...
usbipd: info: usbipd-win: device attached successfully
```

### Step 3: Verify WSL2 Sees USB Device

```bash
# In WSL2
lsusb
# Should show the USB audio device
```

### Step 4: Configure Docker-OSX for USB Passthrough

Add to `docker-compose.yml`:

```yaml
devices:
  - /dev/bus/usb  # Pass through all USB devices
```

Or for specific device:
```yaml
devices:
  - /dev/bus/usb/010/002  # Replace with actual device path
```

### Step 5: Restart Container and Test

```powershell
docker-compose down
docker-compose up -d
```

Then in macOS:
```bash
system_profiler SPAudioDataType
# Should now show the USB audio device
```

---

## Alternative Options

If USB passthrough doesn't work:

### Option A: dockurr/macos (Different Image)
- Built-in `AUDIO_OUTPUT`/`AUDIO_INPUT` support
- Trade-off: Need to rebuild macOS environment
- [Research guide](https://blog.csdn.net/gitblog_01095/article/details/151168003)

### Option B: File-Based Audio Testing
- Export audio from macOS to shared volume
- Play on Windows host
- Already configured via VirtioFS
- No real-time monitoring but functional

---

## Resources

- [usbipd-win GitHub](https://github.com/dorssel/usbipd-win)
- [Microsoft WSL USB Documentation](https://devblogs.microsoft.com/commandline/connecting-usb-devices-to-wsl/)
- [Docker-OSX PulseAudio Guide](https://blog.csdn.net/gitblog_00505/article/details/151808556)
