# Get all Azure AD Application Proxy application wildcard published apps

$AADAPServPrinc=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

$allApps=Get-AzureADApplication -Top 100000 

$AADAPApp=$AADAPServPrinc | ForEach-Object { $allApps -match $_.AppId} 

 

foreach ($item in $AADAPApp) { 

    $tempApps=Get-AzureADApplicationProxyApplication -ObjectId $item.ObjectId

    If ($tempApps.ExternalUrl -match "\*.") 
    
     {
       $AADAPServPrinc[$AADAPApp.IndexOf($item)].DisplayName + " (AppId: " + $AADAPServPrinc[$AADAPApp.IndexOf($item)].AppId+")"; 

       $tempApps | select ExternalUrl,InternalUrl,ExternalAuthenticationType, VerifiedCustomDomainCertificatesMetadata | fl

     }
}  

