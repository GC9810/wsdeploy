# Workstation Deployment Script
An automated PowerShell deployment solution for workstation configuration and setup.

## Overview
This PowerShell script automates the deployment process for workstations, including system configuration, software installation, security settings, and network setup. It reduces manual setup time and ensures consistent configuration across all workstations.

## Features
- Automated system configuration
- Software installation (Chrome, Adobe Reader, MS Office)
- Security settings implementation
- Network and printer setup
- System monitoring configuration
- Detailed logging and reporting

## Prerequisites
- Windows 10/11 Pro or Enterprise
- PowerShell 5.1 or higher
- Administrative privileges
- Network access to network shares
- Winget package manager installed
- TPM 2.0 (for BitLocker)
- Minimum 8GB RAM recommended

## Directory Structure
```plaintext
Workstation-Deployment/
├── Scripts/
│   └── Deploy-Workstation.ps1
├── Config/
│   └── configuration.xml
├── Logs/
│   └── README.md
├── Documentation/
│   ├── Screenshots/
│   └── Troubleshooting.md
└── README.md
```

## Usage
1. Open PowerShell as Administrator
2. Navigate to the script directory
3. Run the script:
```powershell
.\Deploy-Workstation.ps1
```

## What the Script Does

### 1. System Configuration
- Sets computer name (format: BCSS-[SerialNumber])
- Configures Mountain Standard Time zone
- Disables sleep and hibernate modes
- Enables Remote Desktop
- Installs required Windows features

### 2. Security Setup
- Configures Windows Firewall
- Enables Windows Defender
- Sets up BitLocker encryption
- Configures Windows Update settings

### 3. Software Installation
- Google Chrome (set as default browser)
- Adobe Acrobat Reader
- Microsoft Office Suite

### 4. Network Configuration
- Maps Z: drive to \\BCSSD\share
- Installs network printer
- Configures network security settings

### 5. Monitoring Setup
- Enables performance counters
- Configures event logging
- Sets up system monitoring

## Logging
- All deployment actions are logged to: `C:\BCSS_Deploy_Logs`
- Creates a deployment summary report
- Maintains error logs for troubleshooting

## Configuration
To modify settings:

1. Network Paths:
```powershell
$officePath = "\\BCSSD\share\Software\Office\setup.exe"
$printerPath = "\\BCSSD\PrinterShare"
```

2. Windows Features:
```powershell
$windowsFeatures = @(
    "NET-Framework-45-Core",
    "RSAT-File-Services",
    "Telnet-Client"
)
```

## Troubleshooting

### Common Issues

1. Script Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

2. Network Drive Mapping Fails
- Verify network connectivity
- Check user permissions
- Ensure share paths are correct

3. Software Installation Failures
- Verify internet connectivity
- Check Winget installation
- Confirm administrative privileges

4. BitLocker Issues
- Verify TPM status
- Check BIOS settings
- Ensure sufficient disk space

## Best Practices
1. Always run a test deployment in a controlled environment
2. Backup important data before deployment
3. Review logs after deployment
4. Verify all features are working post-deployment

## Security Considerations
- Script requires administrative privileges
- Contains secure network paths
- Implements Windows security features
- Enables system monitoring
