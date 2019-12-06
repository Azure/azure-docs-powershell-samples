# This sample script gets all Azure AD Application Proxy applications (AppId, Name of the app, external / internal url, authentication type).
#
# This script requires PowerShell 5.1 (x64) and one of the following modules:
#     AzureAD 2.0.2.52
#     AzureADPreview 2.0.2.53
#
# Before you begin:
#    Run Connect-AzureAD to connect to the tenant domain.
#    Required Azure AD role: Global Administrator or Application Administrator or Application Developer

Write-Host "Reading service principals. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green" 

$aadapServPrinc = Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 

Write-Host "Reading Azure AD applications. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$allApps = Get-AzureADApplication -Top 100000

Write-Host "Reading application. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapApp = $aadapServPrinc | ForEach-Object { $allApps -match $_.AppId}

Write-Host "Displaying all Azure AD Application Proxy applications with configuration details..." -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host " "

foreach ($item in $aadapApp) {
    $aadapServPrinc[$aadapApp.IndexOf($item)].DisplayName + " (AppId: " + $aadapServPrinc[$aadapApp.IndexOf($item)].AppId + ")";
    Get-AzureADApplicationProxyApplication -ObjectId $item.ObjectId | fl ExternalUrl, InternalUrl,ExternalAuthenticationType
}

Write-Host ("")
Write-Host ("Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("") 
