# Workstation Deployment Script
# Author: GC

#Requires -RunAsAdministrator
#Requires -Version 5.1

# Start Logging
$LogPath = "C:\BCSS_Deploy_Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath
}
Start-Transcript -Path "$LogPath\deployment_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

try {
    Write-Host "Starting BCSS workstation deployment..." -ForegroundColor Green

    # 1. Basic System Setup
    $serialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber
    $newName = "BCSS-$serialNumber"
    Rename-Computer -NewName $newName

    # 2. Time Zone and Power Settings
    Set-TimeZone -Id "Mountain Standard Time"
    powercfg /change monitor-timeout-ac 0
    powercfg /change standby-timeout-ac 0
    powercfg /change hibernate-timeout-ac 0

    # 3. Windows Settings and Features
    Write-Host "Configuring Windows settings and features..." -ForegroundColor Yellow
    
    # Enable Remote Desktop
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    
    # Install Required Windows Features
    Write-Host "Installing Windows Features..." -ForegroundColor Yellow
    $windowsFeatures = @(
        "NET-Framework-45-Core",
        "RSAT-File-Services",
        "Telnet-Client"
    )
    foreach ($feature in $windowsFeatures) {
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
    }

    # Disable unnecessary Windows Features
    Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart

    # 4. Security Settings
    Write-Host "Configuring security settings..." -ForegroundColor Yellow
    
    # Configure Windows Firewall
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    
    # Enable Windows Defender
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-MpPreference -DisableIOAVProtection $false
    
    # Configure Windows Update
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value 4
    
    # Enable BitLocker (if supported)
    if (Get-Command "Enable-BitLocker" -ErrorAction SilentlyContinue) {
        $BitLockerReadiness = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
        if ($BitLockerReadiness.ProtectionStatus -eq "Off") {
            Enable-BitLocker -MountPoint "C:" -EncryptionMethod Aes256 -UsedSpaceOnly -SkipHardwareTest
        }
    }

    # 5. Basic Monitoring Setup
    Write-Host "Configuring system monitoring..." -ForegroundColor Yellow
    
    # Enable Performance Counters
    Enable-WindowsOptionalFeature -Online -FeatureName "PerfMonAgent" -NoRestart
    
    # Configure Event Log Settings
    Limit-EventLog -LogName Application -MaximumSize 20MB
    Limit-EventLog -LogName System -MaximumSize 20MB
    Limit-EventLog -LogName Security -MaximumSize 30MB
    
    # Enable Common Event Logs
    Write-Host "Enabling detailed event logging..." -ForegroundColor Yellow
    wevtutil sl Microsoft-Windows-TaskScheduler/Operational /e:true
    wevtutil sl "Microsoft-Windows-PowerShell/Operational" /e:true

    # 6. Software Installation
    Write-Host "Installing required applications..." -ForegroundColor Yellow

    # Chrome Installation
    winget install --id Google.Chrome --silent

    # Adobe Reader Installation
    winget install --id Adobe.Acrobat.Reader.64-bit --silent

    # Office Installation
    $officePath = "\\BCSSD\share\Software\Office\setup.exe"
    if (Test-Path $officePath) {
        Start-Process -FilePath $officePath -ArgumentList "/configure configuration.xml" -Wait
    } else {
        Write-Host "Office installation files not found!" -ForegroundColor Red
    }

    # 7. Browser and Network Configuration
    # Set Chrome as Default Browser
    Start-Process "$env:ProgramFiles\Google\Chrome\Application\chrome.exe" -ArgumentList "--make-default-browser" -Wait

    # Map Network Drive
    if (!(Test-Path "Z:")) {
        New-PSDrive -Name "Z" -PSProvider FileSystem -Root "\\BCSSD\share" -Persist
    }

    # Install Printer
    $printerPath = "\\BCSSD\PrinterShare"
    Add-Printer -ConnectionName $printerPath

    # 8. Additional System Optimizations
    Write-Host "Performing system optimizations..." -ForegroundColor Yellow
    
    # Disable unnecessary services
    $servicesToDisable = @(
        "XboxGipSvc",
        "XblAuthManager",
        "XblGameSave",
        "XboxNetApiSvc"
    )
    foreach ($service in $servicesToDisable) {
        Set-Service -Name $service -StartupType Disabled
    }

    # Configure System Performance Options
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2

    Write-Host "Deployment completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error during deployment: $_" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Stop-Transcript
}

# Create summary report
$summaryReport = @"
BCSS Deployment Summary
----------------------
Computer Name: $newName
Deployment Time: $(Get-Date)
Windows Features Installed: $($windowsFeatures -join ', ')
Security Settings: Enabled
Monitoring: Configured
Software Installed: Chrome, Adobe Reader, Office
Network Drive: Z: mapped
Printer: Installed
"@

Add-Content -Path "$LogPath\deployment_summary.txt" -Value $summaryReport

# Prompt for restart
$restart = Read-Host "Deployment complete. Restart computer now? (y/n)"
if ($restart -eq 'y') {
    Restart-Computer -Force
}
