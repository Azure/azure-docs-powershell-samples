# Get all Azure AD Application Proxy applications published with the identical certificate

$certThumbprint="REPLACE_WITH_THE_THUMPRINT_OF_THE_CERTIFICATE"

$AADAPServPrinc=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

$allApps=Get-AzureADApplication -Top 100000 

$AADAPApp=$AADAPServPrinc | ForEach-Object { $allApps -match $_.AppId} 

 

foreach ($item in $AADAPApp) { 

    $tempApps=Get-AzureADApplicationProxyApplication -ObjectId $item.ObjectId

    If ($tempApps.VerifiedCustomDomainCertificatesMetadata -match $certThumbprint) 
    
     {
       $AADAPServPrinc[$AADAPApp.IndexOf($item)].DisplayName + " (AppId: " + $AADAPServPrinc[$AADAPApp.IndexOf($item)].AppId+")"; 

       $tempApps | select ExternalUrl,InternalUrl,ExternalAuthenticationType | fl

     }
}  
 
# Get all the Azure AD Application Proxy applications published with the identical certificate and replace it with a new one

$certThumbprint="REPLACE_WITH_THE_THUMPRINT_OF_THE_CERTIFICATE"
$PFXFilePath = "REPLACE_WITH_THE_PATH_TO_THE_PFX_FILE"
$securePassword = Read-Host -AsSecureString // please provide the password of the pfx file


$AADAPServPrinc=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

$allApps=Get-AzureADApplication -Top 100000 

$AADAPApp=$AADAPServPrinc | ForEach-Object { $allApps -match $_.AppId} 

 

foreach ($item in $AADAPApp) 
{ 

    $tempApps=Get-AzureADApplicationProxyApplication -ObjectId $item.ObjectId

    Write-Host ("")
    Write-Host ("SSL certificate change for the Azure AD Application Proxy apps below:")
    Write-Host ("")

    If ($tempApps.VerifiedCustomDomainCertificatesMetadata -match $certThumbprint) 
    
     {
       $AADAPServPrinc[$AADAPApp.IndexOf($item)].DisplayName + " (AppId: " + $AADAPServPrinc[$AADAPApp.IndexOf($item)].AppId+")"; 

       $tempApps | select ExternalUrl,InternalUrl,ExternalAuthenticationType | fl

       Set-AzureADApplicationProxyApplicationCustomDomainCertificate -ObjectId  $item.ObjectId -PfxFilePath $PFXFilePath -Password $securePassword

     }
}

Write-Host ("")
Write-Host ("Finished.")
Write-Host ("") 
