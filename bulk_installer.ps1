# This script handles silent installation of multiple common software packages

# Set error action preference
$ErrorActionPreference = 'Stop'

# Create temp directory if it doesn't exist
$tempPath = "C:\Temp\SoftwareInstall"
if (!(Test-Path $tempPath)) {
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
}

# Function to write to log
function Write-InstallLog {
    param (
        [string]$Message
    )
    $logFile = Join-Path $tempPath "software_install.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Output $logMessage
}

# Function to download installer
function Download-Installer {
    param (
        [string]$Url,
        [string]$OutFile
    )
    try {
        Write-InstallLog "Downloading from $Url to $OutFile"
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutFile)
        return $true
    } catch {
        Write-InstallLog "Error downloading: $_"
        return $false
    }
}

# Function to install software
function Install-Software {
    param (
        [string]$InstallerPath,
        [string]$SilentArgs,
        [string]$SoftwareName,
        [string]$Type = "exe"  # Default to exe if not specified
    )

    try {
        Write-InstallLog "Starting installation of $SoftwareName"
        
        if ($Type -eq "msi") {
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$InstallerPath`" $SilentArgs" -Wait -NoNewWindow -PassThru
        } else {
            $process = Start-Process -FilePath $InstallerPath -ArgumentList $SilentArgs -Wait -NoNewWindow -PassThru
        }

        if ($process.ExitCode -eq 0) {
            Write-InstallLog "$SoftwareName installation completed successfully"
            return $true
        } else {
            Write-InstallLog "$SoftwareName installation failed with exit code: $($process.ExitCode)"
            return $false
        }
    } catch {
        Write-InstallLog "Error installing $SoftwareName: $_"
        return $false
    }
}

# Software Installation Definitions
# Comment out any software you don't want to install
$softwareList = @(
    # Google Chrome Enterprise
    @{
        Name = "Google Chrome Enterprise"
        Url = "https://dl.google.com/chrome/install/latest/chrome_enterprise64.msi"
        OutFile = "$tempPath\chrome_enterprise64.msi"
        Args = "/qn /norestart ALLUSERS=1"
        Type = "msi"
    },
    
    # Bluebeam Revu 21 (Update URL as needed)
    @{
        Name = "Bluebeam Revu 21"
        Url = "<YOUR_REVU_21_URL>" # Replace with actual download URL
        OutFile = "$tempPath\revu21_installer.msi"
        Args = "/qn /norestart"
        Type = "msi"
    },
    
    # Adobe Acrobat Reader DC
    @{
        Name = "Adobe Acrobat Reader DC"
        Url = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/latest/AcroRdrDC_en_US.exe"
        OutFile = "$tempPath\AcroRdrDC.exe"
        Args = "/sAll /rs /msi EULA_ACCEPT=YES"
        Type = "exe"
    },
    
    # Microsoft Teams
    @{
        Name = "Microsoft Teams"
        Url = "https://aka.ms/teamsdownload/windows64"
        OutFile = "$tempPath\teams_windows_x64.exe"
        Args = "-s"
        Type = "exe"
    },
    
    # Zoom
    @{
        Name = "Zoom"
        Url = "https://zoom.us/client/latest/ZoomInstallerFull.msi"
        OutFile = "$tempPath\ZoomInstallerFull.msi"
        Args = "/qn /norestart ZoomAutoUpdate=`"true`""
        Type = "msi"
    }
)

# Main installation process
Write-InstallLog "Starting bulk software installation process"

foreach ($software in $softwareList) {
    Write-InstallLog "Processing $($software.Name)"
    
    try {
        # Download installer
        if (Download-Installer -Url $software.Url -OutFile $software.OutFile) {
            # Install software
            Install-Software -InstallerPath $software.OutFile -SilentArgs $software.Args -SoftwareName $software.Name -Type $software.Type
        }
        
        # Cleanup installer
        if (Test-Path $software.OutFile) {
            Remove-Item $software.OutFile -Force
            Write-InstallLog "Cleaned up installer for $($software.Name)"
        }
    }
    catch {
        Write-InstallLog "Error processing $($software.Name): $_"
        continue
    }
}

# Cleanup temp directory if empty
if ((Get-ChildItem $tempPath | Measure-Object).Count -eq 0) {
    Remove-Item $tempPath -Force
}

Write-InstallLog "Bulk software installation process completed"

# Export the log content to NinjaRMM
$logContent = Get-Content (Join-Path $tempPath "software_install.log") -Raw
Write-Output $logContent
