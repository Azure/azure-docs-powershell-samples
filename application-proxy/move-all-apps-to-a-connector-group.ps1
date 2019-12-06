# This sample script moves all applications assigned to a specific connector group to another connector group.
#
# .\move-all-apps-to-a-connector-group.ps1 -CurrentConnectorGroupId <ObjectId of the current connector group> -NewConnectorGroupId <ObjectId of the new connector group>
#
# This script requires PowerShell 5.1 (x64) and one of the following modules:
#     AzureAD 2.0.2.52
#     AzureADPreview 2.0.2.53
#
# Before you begin:
#    Run Connect-AzureAD to connect to the tenant domain.
#    Required Azure AD role: Global Administrator or Application Administrator

param(
[string] $CurrentConnectorGroupId = "null",
[string] $NewConnectorGroupId = "null"
)

$currentGroupId = $CurrentConnectorGroupId
$newGroupId = $NewConnectorGroupId

If (($currentGroupId -eq "null") -or ($newGroupId -eq "null")) {

    Write-Host "Parameter is missing." -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "
    Write-Host ".\move-all-apps-to-a-connector-group.ps1 -CurrentConnectorGroupId <ObjectId of the current connector group> -NewConnectorGroupId <ObjectId of the new connector group>" -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "

    Exit
}

Try {
$temp = Get-AzureADApplicationProxyConnectorGroup -Id $currentGroupId
$temp = Get-AzureADApplicationProxyConnectorGroup -Id $newGroupId
}

Catch {
    Write-Host "Possibly, one of the parameters is incorrect." -BackgroundColor "Black" -ForegroundColor "Red"
    Write-Host " "

    Exit
}

Write-Host "Reading service principals. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapServPrinc = Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

Write-Host "Reading Azure AD applications. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$allApps = Get-AzureADApplication -Top 100000 

Write-Host "Reading application. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapApp = $aadapServPrinc | ForEach-Object { $allApps -match $_.AppId} 

Write-Host "Displaying Azure AD Application Proxy applications moved from the connector Id :",$currentGroupId," to: ",$newGroupId -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host " "

foreach ($item in $aadapApp) {

      $connector = Get-AzureADApplicationProxyApplicationConnectorGroup -ObjectId $item.ObjectID;

      If ($currentGroupId -eq $connector.Id) {
            
      $name = $aadapServPrinc -match $item.AppId            
      $name.DisplayName + " (AppId: " + $item.AppId + ")"
            
      Set-AzureADApplicationProxyApplicationConnectorGroup -ObjectId $item.ObjectId -ConnectorGroupId $newGroupId
            
      }
} 

Write-Host ("")
Write-Host ("All apps has been moved to the new connector. Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("") 

