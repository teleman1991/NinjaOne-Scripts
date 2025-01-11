# Advanced Software Deployment Script for NinjaOne
# This script provides comprehensive software deployment with prerequisites checking and logging

function Install-ManagedSoftware {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SoftwareName,
        [string]$InstallerPath,
        [string]$MinimumDiskSpace = "5GB",
        [string]$MinimumRAM = "4GB",
        [string[]]$Prerequisites = @()
    )
    
    $log = @{
        SoftwareName = $SoftwareName
        StartTime = Get-Date
        Status = "Starting"
        Steps = @()
    }
    
    # Check System Requirements
    try {
        # Convert size strings to bytes
        $requiredSpace = [long]($MinimumDiskSpace -replace "GB") * 1GB
        $requiredRAM = [long]($MinimumRAM -replace "GB") * 1GB
        
        # Check disk space
        $systemDrive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
        if ($systemDrive.FreeSpace -lt $requiredSpace) {
            throw "Insufficient disk space. Required: $MinimumDiskSpace, Available: $([math]::Round($systemDrive.FreeSpace/1GB, 2))GB"
        }
        
        # Check RAM
        $ram = Get-WmiObject Win32_ComputerSystem
        if ($ram.TotalPhysicalMemory -lt $requiredRAM) {
            throw "Insufficient RAM. Required: $MinimumRAM, Available: $([math]::Round($ram.TotalPhysicalMemory/1GB, 2))GB"
        }
        
        $log.Steps += @{
            Step = "System Requirements Check"
            Status = "Passed"
            Time = Get-Date
        }
    } catch {
        $log.Status = "Failed"
        $log.Error = $_.Exception.Message
        return $log | ConvertTo-Json -Depth 4
    }
    
    # Check and Install Prerequisites
    foreach ($prereq in $Prerequisites) {
        try {
            $installed = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$prereq*" }
            if (-not $installed) {
                # Add prerequisite installation logic here
                $log.Steps += @{
                    Step = "Installing Prerequisite: $prereq"
                    Status = "In Progress"
                    Time = Get-Date
                }
            }
        } catch {
            $log.Steps += @{
                Step = "Prerequisite Check: $prereq"
                Status = "Failed"
                Error = $_.Exception.Message
                Time = Get-Date
            }
        }
    }
    
    # Main Installation
    try {
        if (Test-Path $InstallerPath) {
            $extension = [System.IO.Path]::GetExtension($InstallerPath)
            
            switch ($extension) {
                '.msi' {
                    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$InstallerPath`" /quiet /norestart" -Wait -PassThru
                }
                '.exe' {
                    $process = Start-Process -FilePath $InstallerPath -ArgumentList "/quiet /norestart" -Wait -PassThru
                }
                default {
                    throw "Unsupported installer type: $extension"
                }
            }
            
            if ($process.ExitCode -eq 0) {
                $log.Status = "Completed"
                $log.Steps += @{
                    Step = "Main Installation"
                    Status = "Completed"
                    Time = Get-Date
                }
            } else {
                throw "Installation failed with exit code: $($process.ExitCode)"
            }
        } else {
            throw "Installer not found at: $InstallerPath"
        }
    } catch {
        $log.Status = "Failed"
        $log.Error = $_.Exception.Message
        $log.Steps += @{
            Step = "Main Installation"
            Status = "Failed"
            Error = $_.Exception.Message
            Time = Get-Date
        }
    }
    
    $log.EndTime = Get-Date
    return $log | ConvertTo-Json -Depth 4
}

# Example usage:
# Install-ManagedSoftware -SoftwareName "My Application" -InstallerPath "C:\Installers\MyApp.msi" -MinimumDiskSpace "10GB" -MinimumRAM "8GB" -Prerequisites @("Visual C++ Runtime", ".NET Framework 4.8")