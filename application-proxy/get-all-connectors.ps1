# Sample script: Get all Azure AD Application Proxy Connector groups with the included connectors
#
# Required AAD role: Global Administrator or Application Administrator
#
# PowerShell 5.1 (x64), module: AzureAD 2.0.2.52 / AzureADPreview 2.0.2.53

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
