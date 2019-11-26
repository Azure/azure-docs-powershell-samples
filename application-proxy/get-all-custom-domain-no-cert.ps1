# Sample script: Get all Azure AD Application Proxy applications using custom domain with no certificate
#
# Required AAD role: Global Administrator or Application Administrator or Application Developer
#
# PowerShell 5.1 (x64), module: AzureAD 2.0.2.52 / AzureADPreview 2.0.2.53

Write-Host "Reading service principals. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapServPrinc = Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

Write-Host "Reading Azure AD applications. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$allApps = Get-AzureADApplication -Top 100000 

Write-Host "Reading application. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapApp = $aadapServPrinc | ForEach-Object { $allApps -match $_.AppId} 

Write-Host "Displaying custom domain Azure AD Application Proxy applications with no uploaded certificates..." -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host " "

foreach ($item in $aadapApp) { 

    $tempApps = Get-AzureADApplicationProxyApplication -ObjectId $item.ObjectId

    If ($tempApps.ExternalUrl -notmatch ".msappproxy.net") {

     If ($tempApps.VerifiedCustomDomainCertificatesMetadata -notmatch "class") {

       $aadapServPrinc[$aadapApp.IndexOf($item)].DisplayName + " (AppId: " + $aadapServPrinc[$aadapApp.IndexOf($item)].AppId + ")"; 

       $tempApps | select ExternalUrl,InternalUrl,ExternalAuthenticationType, VerifiedCustomDomainCertificatesMetadata | fl

     }
   }
}   

Write-Host ("")
Write-Host ("Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("") 
