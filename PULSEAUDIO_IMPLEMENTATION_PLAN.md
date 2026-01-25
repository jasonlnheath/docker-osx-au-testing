# Docker-OSX: PulseAudio Implementation Plan (Safe Incremental Approach)

**Date:** 2025-01-23
**Goal:** Enable Core Audio output via PulseAudio to Windows host speakers

---

## Critical Findings

### Issue 1: Wrong WSLg PulseAudio Socket Path
**Incorrect:** `/mnt/wslg/runtime-dir/pulse/native`
**Correct:** `/mnt/wslg/PulseServer`

**Source:** [Docker-OSX音频配置：ALSA与PulseAudio音频输出全攻略](https://blog.csdn.net/gitblog_00505/article/details/151808556)

### Issue 2: Missing Persistent Disk Volume
Container was booting to recovery mode because `macos-disk:/home/arch/OSX-KVM` volume was missing.

### Issue 3: Duplicate HDA Devices
Adding `-device intel-hda -device hda-duplex` to EXTRA causes "no default audio driver available" error. Docker-OSX handles this automatically when `AUDIO_DRIVER` is set.

---

## Pre-Flight Checks

```bash
# 1. Verify WSLg PulseAudio socket exists
ls -la /mnt/wslg/PulseServer
# Expected: srwxrwxrwx socket file

# 2. Backup existing working configuration
cp macos-docker-au/docker-compose.yml.backup macos-docker-au/docker-compose.yml.pre-audio-backup
```

---

## Incremental Rollout (4 Steps)

### Step 0: Verify Baseline
```bash
cd macos-docker-au
cp docker-compose.yml.backup docker-compose.yml
docker-compose down
docker-compose up -d
# Wait 60-90 seconds, verify macOS boots (NOT recovery mode)
docker-compose down
```

### Step 1: Add WSLg Mount Only
**Edit docker-compose.yml volumes section:**
```yaml
volumes:
  # ... existing volumes from backup ...
  - /mnt/wslg:/mnt/wslg
```

**Test:**
```bash
docker-compose up -d
docker exec macos-au-tester ls -la /mnt/wslg/PulseServer
docker-compose down
```

### Step 2: Add AUDIO_DRIVER Only
**Edit docker-compose.yml environment section:**
```yaml
environment:
  # ... existing ...
  - AUDIO_DRIVER=pa,server=unix:/mnt/wslg/PulseServer
```

**Test:**
```bash
docker-compose up -d
docker logs macos-au-tester | grep -i audio
# Verify no "no default audio driver available" error
docker-compose down
```

### Step 3: Add PULSE_SERVER (Final)
**Edit docker-compose.yml environment section:**
```yaml
environment:
  # ... existing ...
  - PULSE_SERVER=unix:/mnt/wslg/PulseServer
```

**Test:**
```bash
docker-compose up -d
# Wait 60-90 seconds for macOS boot
ssh -p 50922 user@localhost "afplay /System/Library/Sounds/Glass.aiff"
# Expected: Sound on Windows host speakers
```

---

## Complete docker-compose.yml Configuration

```yaml
version: '3.8'

services:
  macos-au-tester:
    image: sickcodes/docker-osx:latest
    container_name: macos-au-tester
    privileged: true
    ports:
      - "5999:5999"
      - "50922:10022"
    environment:
      - RAM=16
      - SMP=4
      - CORES=4
      - GENERATE_UNIQUE=true
      - DEVICE_MODEL=iMacPro1,1
      - SHORTNAME=monterey
      # Audio configuration for PulseAudio (WSLg)
      - AUDIO_DRIVER=pa,server=unix:/mnt/wslg/PulseServer
      - PULSE_SERVER=unix:/mnt/wslg/PulseServer
      # VirtioFS enablement via QEMU -virtfs flags
      - EXTRA=-display none -vnc 0.0.0.0:99 -virtfs local,path=/host-source,mount_tag=host-source,security_model=mapped-xattr -virtfs local,path=/host-build,mount_tag=host-build,security_model=mapped-xattr
    cap_add:
      - SYS_ADMIN
    devices:
      - /dev/kvm
      - /dev/fuse
    volumes:
      # === Named Volumes (Persistent Data) ===
      - macos-disk:/home/arch/OSX-KVM
      - xcode-cache:/home/arch/xcode-cache:rw
      - build-cache:/home/arch/build-cache:rw
      - ssh-keys:/home/arch/.ssh:rw
      - homebrew-cache:/home/arch/Library/Caches/Homebrew:rw

      # === Bind Mounts (VirtioFS) ===
      - /mnt/c/dev/HeathAudio:/host-source:ro,consistent
      - /mnt/c/dev/HeathAudio/build:/host-build:rw,consistent

      # === WSLg PulseAudio ===
      - /mnt/wslg:/mnt/wslg

    tmpfs:
      - /tmp:noexec,size=2g
      - /var/tmp:noexec,size=1g

    networks:
      - macos-net

volumes:
  macos-disk:
    driver: local

  xcode-cache:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/xcode-cache

  build-cache:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/build-cache

  ssh-keys:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/ssh-keys

  homebrew-cache:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/homebrew-cache

networks:
  macos-net:
    driver: bridge
```

---

## Rollback Plan

If any step fails:
```bash
docker-compose down
cp docker-compose.yml.backup docker-compose.yml
docker-compose up -d
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Recovery mode boot | Missing macos-disk volume | Restore from backup |
| "no default audio driver" | Duplicate HDA devices in EXTRA | Remove -device intel-hda -device hda-duplex |
| Cannot access /mnt/wslg | Missing WSLg mount | Add -v /mnt/wslg:/mnt/wslg |
| No sound output | Wrong socket path | Use /mnt/wslg/PulseServer |

---

## Sources

- [Docker-OSX音频配置：ALSA与PulseAudio音频输出全攻略](https://blog.csdn.net/gitblog_00505/article/details/151808556)
- [sickcodes/Docker-OSX GitHub](https://github.com/sickcodes/Docker-OSX)
- [Docker Desktop Backup Documentation](https://docs.docker.com/desktop/settings-and-safety/backup-restore/)
