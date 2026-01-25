# macOS Docker AU Tester - Windows Setup Script
# Run this in PowerShell as Administrator

Write-Host "=== macOS Docker AU Tester - Windows/WSL2 Setup ===" -ForegroundColor Cyan

# Check Windows version
$windowsVersion = [Environment]::OSVersion.Version
Write-Host "Windows Version: $($windowsVersion)" -ForegroundColor Green

# Step 1: Enable WSL
Write-Host "`n[1/6] Enabling WSL..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Step 2: Check .wslconfig for nested virtualization
Write-Host "`n[2/6] Configuring nested virtualization..." -ForegroundColor Yellow
$wslConfigPath = "$env:USERPROFILE\.wslconfig"
if (-not (Test-Path $wslConfigPath)) {
    Write-Host "Creating .wslconfig..." -ForegroundColor Gray
    New-Item -Path $wslConfigPath -ItemType File -Force | Out-Null
}

$configContent = Get-Content $wslConfigPath -Raw -ErrorAction SilentlyContinue
if ($configContent -notmatch "nestedVirtualization") {
    Add-Content $wslConfigPath "`n[wsl2]`nnestedVirtualization=true"
    Write-Host "Added nestedVirtualization=true to .wslconfig" -ForegroundColor Green
} else {
    Write-Host "nestedVirtualization already configured" -ForegroundColor Green
}

# Step 3: Check WSL version
Write-Host "`n[3/6] Checking WSL version..." -ForegroundColor Yellow
wsl --list --verbose
Write-Host "`nIf WSL2 is not set as default, run: wsl --set-default-version 2" -ForegroundColor Yellow

# Step 4: Check Docker Desktop
Write-Host "`n[4/6] Checking Docker Desktop..." -ForegroundColor Yellow
$dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerInstalled) {
    Write-Host "Docker Desktop not found!" -ForegroundColor Red
    Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    Write-Host "After installation, ensure these settings are enabled:" -ForegroundColor Yellow
    Write-Host "  - Settings > General > 'Use the WSL2 based engine'" -ForegroundColor Gray
    Write-Host "  - Settings > Resources > WSL Integration > Enable integration" -ForegroundColor Gray
} else {
    Write-Host "Docker found: $(docker --version)" -ForegroundColor Green
}

# Step 5: Check WSL2 KVM support
Write-Host "`n[5/6] Checking WSL2 KVM support..." -ForegroundColor Yellow
Write-Host "Run the following in WSL to verify KVM:" -ForegroundColor Gray
Write-Host "  wsl" -ForegroundColor Cyan
Write-Host "  kvm-ok" -ForegroundColor Cyan
Write-Host "If KVM is not available, run:" -ForegroundColor Gray
Write-Host "  sudo apt update && sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils cpu-checker" -ForegroundColor Cyan

# Step 6: Install VNC viewer
Write-Host "`n[6/6] VNC Viewer for GUI access..." -ForegroundColor Yellow
Write-Host "For VNC access, install a VNC viewer:" -ForegroundColor Gray
Write-Host "  - RealVNC Viewer: https://www.realvnc.com/en/connect/download/viewer/" -ForegroundColor Cyan
Write-Host "  - Or use: chocolatey install vnc-viewer" -ForegroundColor Cyan

# Summary
Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Restart your computer if this was the first time enabling WSL" -ForegroundColor White
Write-Host "  2. Open WSL: wsl" -ForegroundColor White
Write-Host "  3. Navigate to project: cd $($(Get-Location).Path.Replace('\','/').Replace('C:','/c'))" -ForegroundColor White
Write-Host "  4. Run: ./setup-macos-container.sh" -ForegroundColor White
Write-Host "`n  Or use Docker Compose directly:" -ForegroundColor White
Write-Host "  docker compose up -d" -ForegroundColor Cyan

Write-Host "`nFor WSLg GUI access, the container will use your WSLg X11 server automatically." -ForegroundColor Green
