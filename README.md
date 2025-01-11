# NinjaOne Scripts Collection

This repository contains a collection of PowerShell and Python scripts for use with NinjaOne RMM platform. These scripts are designed to help with common system administration tasks, monitoring, and maintenance.

## Scripts Overview

### system_health_check.ps1
A comprehensive system health monitoring script that checks:
- CPU Usage
- Memory Usage
- Disk Space
- System Uptime
- Network Connectivity

### disk_cleanup.ps1
An automated disk cleanup script that:
- Clears temporary files
- Cleans Windows Update cache
- Empties Recycle Bin
- Reports on space saved and remaining disk space

## Usage
Each script can be run independently through NinjaOne's script execution feature. Scripts are designed to be modular and return structured output for easy integration with NinjaOne's monitoring and alerting system.