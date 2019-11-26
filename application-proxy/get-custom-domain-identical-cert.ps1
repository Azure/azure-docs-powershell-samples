# Sample script: Get all Azure AD Application Proxy applications published with the identical certificate
#
# .\get-custom-domain-identical-cert.ps1 -Thumbprint <thumbprint of the certificate>
#
# Required AAD role: Global Administrator or Application Administrator
#
# PowerShell 5.1 (x64), module: , AzureAD 2.0.2.52 / AzureADPreview 2.0.2.53

param(
[string] $Thumbprint = "null"
)

$certThumbprint = $Thumbprint 


If ($certThumbprint -eq "null") {

    Write-Host "Parameter is missing." -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "
    Write-Host ".\get-custom-domain-identical-cert.ps1 -Thumbprint <thumbprint of the certificate>" -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "

    Exit
}

Write-Host "Reading service principals. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapServPrinc = Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

Write-Host "Reading Azure AD applications. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$allApps = Get-AzureADApplication -Top 100000 

Write-Host "Reading application. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapApp = $aadapServPrinc | ForEach-Object { $allApps -match $_.AppId} 

Write-Host "Displaying all Azure AD Application Proxy applications published with the identical certificate (", $certThumbprint,")" -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host " "

foreach ($item in $aadapApp) { 

    $tempApps = Get-AzureADApplicationProxyApplication -ObjectId $item.ObjectId

    If ($tempApps.VerifiedCustomDomainCertificatesMetadata -match $certThumbprint) {

       $aadapServPrinc[$aadapApp.IndexOf($item)].DisplayName + " (AppId: " + $aadapServPrinc[$aadapApp.IndexOf($item)].AppId + ")"; 

       $tempApps | select ExternalUrl,InternalUrl,ExternalAuthenticationType | fl

    }
}  
 
Write-Host ("")
Write-Host ("Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("") 
