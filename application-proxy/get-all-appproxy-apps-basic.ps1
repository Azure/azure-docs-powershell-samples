# Sample script: Get all Azure AD Application Proxy applications (AppId, Name of the app, ObjID) 
#
# Required AAD role: Global Administrator or Application Administrator or Application Developer
#
# PowerShell 5.1 (x64), module: AzureAD 2.0.2.52 / AzureADPreview 2.0.2.53

Write-Host "Reading service principals. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green" 

$aadapServPrinc = Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 

Write-Host "Displaying the Azure AD Application Proxy applications." -BackgroundColor "Black" -ForegroundColor "Green" 
Write-Host " "

$aadapServPrinc | fl AppId, DisplayName, ObjectId

Write-Host " "
Write-Host "Number of Azure AD Application Proxy Applications: ",  $aadapServPrinc.Count
Write-Host " "
 
Write-Host ("")
Write-Host ("Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("") 
