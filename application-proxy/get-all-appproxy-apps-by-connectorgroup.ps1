# This sample script gets all Azure AD Application Proxy Connector groups with the assigned applications.
#
# This script requires PowerShell 5.1 (x64) and one of the following modules:
#     AzureAD 2.0.2.52
#     AzureADPreview 2.0.2.53
#
# Before you begin:
#    Run Connect-AzureAD to connect to the tenant domain.
#    Required Azure AD role: Global Administrator or Application Administrator

Write-Host "Reading service principals. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green" 

$aadapServPrinc = Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 

Write-Host "Reading Azure AD applications. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$allApps = Get-AzureADApplication -Top 100000

Write-Host "Reading application. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapApp = $aadapServPrinc | ForEach-Object { $allApps -match $_.AppId}
 
Write-Host "Reading connector groups. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapConnectorGroups=Get-AzureADApplicationProxyConnectorGroup -Top 100000 

Write-Host "Displaying connector groups and assigned applications..." -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host " "

foreach ($item in $aadapConnectorGroups)
 {
    
   If ($item.ConnectorGroupType -eq "applicationProxy")
    {
     "Connector group: " + $item.Name+ " (Id: " + $item.Id+ ")";
     " ";
     

    foreach ($item2 in $aadapApp)
     {

      $connector = Get-AzureADApplicationProxyApplicationConnectorGroup -ObjectId $item2.ObjectID;

            If ($item.Id -eq $connector.Id) 
            
            {
            
            $name = $aadapServPrinc -match $item2.AppId            
            $name.DisplayName + " (AppId: " + $item2.AppId+ ")"}

     }
     " ";
     }
 }   


Write-Host ("")
Write-Host ("Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("") 
