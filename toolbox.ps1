# Script Name: toolbox.ps1
# Purpose: A menu-driven PowerShell toolbox for IT administration tasks
# Author: Grok 3, based on user-provided scripts and requirements
# Date: June 02, 2025

# Elevate to Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script as an Administrator!"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Function to display the menu
function Show-Menu {
    Clear-Host
    Write-Host "===== IT Admin Toolbox ====="
    Write-Host "0. Run All (Option 1-5)"
    Write-Host "1. Install Software via Winget"
    Write-Host "2. Configure Power Options and Accessibility Settings"
    Write-Host "3. Download Files to Desktop"
    Write-Host "4. Run Activation Script"
    Write-Host "5. Create Desktop Shortcuts (Delete Existing First)"
    Write-Host "6. Exit"
    Write-Host "==========================="
}

# Function to install software using Winget
function Install-Software {
    Write-Host "Checking for Winget..."
    try {
        winget --version | Out-Null
        Write-Host "Winget is installed, proceeding."
    }
    catch {
        Write-Host "Winget not found, attempting to install..."
        try {
            irm "https://aka.ms/getwinget" | iex
        }
        catch {
            Write-Host "Failed to install Winget. Please install it manually."
            return
        }
    }

    $packageIds = @(
        "VideoLAN.VLC",
        "Google.Chrome",
        "Microsoft.Office",
        "liule.Snipaste",
        "Bluebeam.Revu.21",
        "AnyDesk.AnyDesk"
    )

    foreach ($id in $packageIds) {
        Write-Host "Installing $id..."
        winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements
        if ($?) {
            Write-Host "$id installed successfully."
        } else {
            Write-Host "Failed to install $id."
        }
    }
}

# Function to configure power options and accessibility settings
function Configure-Settings {
    Write-Host "Configuring power settings: Never sleep, screen never turns off..."
    powercfg /change standby-timeout-ac 0
    powercfg /change monitor-timeout-ac 0
    powercfg /change standby-timeout-dc 0
    powercfg /change monitor-timeout-dc 0

    Write-Host "Configuring accessibility settings: Disable animations, enable classic context menu..."
    # Disable animations in Accessibility -> Visual Effects
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
    # Enable classic right-click context menu
    New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Name "InprocServer32" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value ""
}

# Function to download files to desktop
function Download-Files {
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $urls = @(
        "https://github.com/GC9810/wsdeploy/raw/refs/heads/main/BB6y7z1GsVbFSs.zip",
        "https://github.com/GC9810/wsdeploy/raw/refs/heads/main/AD5W348FD00wqi.zip"
    )

    foreach ($url in $urls) {
        $fileName = [System.IO.Path]::GetFileName($url)
        $outputPath = Join-Path $DesktopPath $fileName
        Write-Host "Downloading $fileName to $outputPath..."
        try {
            Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
            Write-Host "Downloaded $fileName successfully."
        }
        catch {
            Write-Host "Failed to download $fileName. Error: $_"
        }
    }
}

# Function to run activation script
function Run-Activation {
    Write-Host "Running activation script..."
    try {
        irm https://get.activated.win | iex
    }
    catch {
        Write-Host "Failed to run activation script. Error: $_"
    }
}

# Function to create desktop shortcuts
function Create-Shortcuts {
    $DesktopPaths = @([Environment]::GetFolderPath("Desktop"), "C:\Users\Public\Desktop")
    
    # Delete existing shortcuts
    foreach ($DesktopPath in $DesktopPaths) {
        if (Test-Path $DesktopPath) {
            Write-Host "Deleting existing shortcuts on $DesktopPath..."
            $shortcuts = Get-ChildItem -Path $DesktopPath -Filter "*.lnk" -ErrorAction SilentlyContinue
            foreach ($shortcut in $shortcuts) {
                try {
                    Remove-Item -Path $shortcut.FullName -Force -ErrorAction Stop
                    Write-Host "Deleted: $($shortcut.Name)"
                }
                catch {
                    Write-Host "Failed to delete $($shortcut.Name): $_"
                }
            }
        }
    }

    # Function to create a shortcut
    function Create-Shortcut {
        param (
            [string]$TargetPath,
            [string]$ShortcutPath,
            [string]$ShortcutName
        )
        if (Test-Path $TargetPath) {
            $WShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WShell.CreateShortcut("$ShortcutPath\$ShortcutName.lnk")
            $Shortcut.TargetPath = $TargetPath
            $Shortcut.Save()
            Write-Host "Created shortcut for $ShortcutName at $ShortcutPath"
        } else {
            Write-Host "Error: $TargetPath not found. Skipping $ShortcutName shortcut."
        }
    }

    # Define application paths
    $Apps = @{
        "Bluebeam" = "C:\Program Files\Bluebeam Software\Bluebeam Revu\21\Revu\Revu.exe"
        "Word" = "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE"
        "Excel" = "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE"
        "PowerPoint" = "C:\Program Files\Microsoft Office\root\Office16\POWERPNT.EXE"
        "Outlook" = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
        "VLC" = "C:\Program Files\VideoLAN\VLC\vlc.exe"
        "Chrome" = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    }

    # Create shortcuts on the user's desktop
    foreach ($App in $Apps.GetEnumerator()) {
        Create-Shortcut -TargetPath $App.Value -ShortcutPath ([Environment]::GetFolderPath("Desktop")) -ShortcutName $App.Key
    }
}

# Main menu loop
do {
    Show-Menu
    $choice = Read-Host "Please select an option (0-6)"
    
    switch ($choice) {
        "0" {
            Write-Host "Running all options (1-5)..."
            Install-Software
            Configure-Settings
            Download-Files
            Run-Activation
            Create-Shortcuts
            Write-Host "All tasks completed. Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "1" {
            Install-Software
            Write-Host "Software installation completed. Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "2" {
            Configure-Settings
            Write-Host "Settings configuration completed. Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "3" {
            Download-Files
            Write-Host "File download completed. Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "4" {
            Run-Activation
            Write-Host "Activation script executed. Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "5" {
            Create-Shortcuts
            Write-Host "Shortcut creation completed. Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "6" {
            Write-Host "Exiting toolbox..."
            break
        }
        default {
            Write-Host "Invalid option. Please select 0-6. Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
} while ($choice -ne "6")

Write-Host "Toolbox closed."
