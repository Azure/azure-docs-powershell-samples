# This sample script gets all Azure AD Application Proxy Connector groups with the included connectors.
#
# This script requires PowerShell 5.1 (x64) and one of the following modules:
#     AzureAD 2.0.2.52
#     AzureADPreview 2.0.2.53
#
# Before you begin:
#    Run Connect-AzureAD to connect to the tenant domain.
#    Required Azure AD role: Global Administrator or Application Administrator

Write-Host "Reading connector groups. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapConnectorGroups = Get-AzureADApplicationProxyConnectorGroup -Top 100000 

Write-Host "Displaying connector groups and connectors..." -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host " "

foreach ($item in $aadapConnectorGroups) {
   
     If ($item.ConnectorGroupType -eq "applicationProxy") {

     "Connector group: " + $item.Name, "(Id:" + $item.Id + ")";
     Get-AzureADApplicationProxyConnectorGroupMembers -Id $item.Id;
     " ";

     }
}  

Write-Host ("")
Write-Host ("Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("") 
