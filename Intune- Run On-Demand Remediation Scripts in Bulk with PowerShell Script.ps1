<# 
.SYNOPSIS
Run On-Demand Remediation Scripts in Bulk using OnDemandProactiveRemediation using Powershell Script >

.DESCRIPTION
 Run On-Demand Remediation Scripts in Bulk using OnDemandProactiveRemediation using Powershell Script >

.Example
Trigger Windows Update (Check for Windows Update) on multipla device using OnDemandProactiveRemediation using Powershell Script >

.Demo
YouTube video link--> https://www.youtube.com/@ChanderManiPandey


.NOTES
 Version:         1.1
 Author:          Chander Mani Pandey
 Creation Date:   11 May 2025
 Find the author on:  
 YouTube:         https://www.youtube.com/@chandermanipandey8763  
 Twitter:         https://twitter.com/Mani_CMPandey  
 LinkedIn:        https://www.linkedin.com/in/chandermanipandey  
 BlueSky:         https://bsky.app/profile/chandermanipandey.bsky.social
 GitHub:          https://github.com/ChanderManiPandey2022
#>


#=====================User Input File=============================

$RemediationScriptID = "cce53a28-074f-4ab7-8374-c5d99f861e4f"
$Path = "C:\Temp\DeviceList.txt"
$SuccessReportPath = "C:\Temp\SuccessReport.csv"
$FailedReportPath = "C:\Temp\FailedReport.csv"

#=================================================================

# Check if the Microsoft.Graph module is installed
if (-not (Get-Module -Name Microsoft.Graph -ListAvailable)) {
    Write-Host "Microsoft.Graph module not found. Installing..."
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    Write-Host "Microsoft.Graph module installed successfully." -ForegroundColor Green
} else {
    Write-Host "Microsoft.Graph module is already installed." -ForegroundColor Green
}

Write-Host "Importing Microsoft.Graph module..." -ForegroundColor Yellow
Import-Module Microsoft.Graph.Authentication
Write-Host "Microsoft.Graph.Authentication module imported successfully." -ForegroundColor Green

Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.PrivilegedOperations.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

# Get all Windows devices from Intune
$GetManagedDevice = Get-MgDeviceManagementManagedDevice -Filter "OperatingSystem eq 'Windows'" -All | Select-Object Id, DeviceName
Write-Host "Devices found in Intune: $($GetManagedDevice.Count)" -ForegroundColor Cyan

# Read input device names
$InputList = Get-Content -Path $Path
Write-Host "Total devices in the Notepad file: $($InputList.Count)" -ForegroundColor Yellow
Write-Host ""

# Prepare result arrays
$SuccessList = @()
$FailedList = @()

foreach ($DeviceName in $InputList) {
    $MatchedDevice = $GetManagedDevice | Where-Object { $_.DeviceName -eq $DeviceName }

    if ($MatchedDevice) {
        foreach ($Device in $MatchedDevice) {
            $IntuneDeviceID = $Device.Id
            $URL = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$IntuneDeviceID')/initiateOnDemandProactiveRemediation"

            $Body = @{
                "ScriptPolicyId" = "$RemediationScriptID"
            }

            try {
                Invoke-MgGraphRequest -Uri $URL -Method POST -Body $Body -ErrorAction Stop
                Write-Host "✅ Success: $($Device.DeviceName)" -ForegroundColor Green
                $SuccessList += [pscustomobject]@{
                    DeviceName = $Device.DeviceName
                    IntuneDeviceID = $Device.Id
                    Status = "Success"
                    Timestamp = (Get-Date)
                }
            }
            catch {
                Write-Host "❌ Failed to trigger remediation for: $($Device.DeviceName)" -ForegroundColor Red
                $FailedList += [pscustomobject]@{
                    DeviceName = $Device.DeviceName
                    IntuneDeviceID = $Device.Id
                    Status = "Failed to trigger remediation"
                    Timestamp = (Get-Date)
                }
            }
        }
    } else {
        Write-Host "❌ Device '$DeviceName' is NOT present in Intune." -ForegroundColor Red
        $FailedList += [pscustomobject]@{
            DeviceName = $DeviceName
            IntuneDeviceID = ""
            Status = "Not Found in Intune"
            Timestamp = (Get-Date)
        }
    }
}

# Export results to CSV
$SuccessList | Export-Csv -Path $SuccessReportPath -NoTypeInformation -Encoding UTF8
$FailedList  | Export-Csv -Path $FailedReportPath  -NoTypeInformation -Encoding UTF8

Write-Host "`nReports generated:" -ForegroundColor Cyan
Write-Host "✔ Success report: $SuccessReportPath"
Write-Host "❌ Failed report:  $FailedReportPath"
