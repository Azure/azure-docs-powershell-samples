# Get all Azure AD Application Proxy application custom domain applications

$AADAPServPrinc=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

$allApps=Get-AzureADApplication -Top 100000 

$AADAPApp=$AADAPServPrinc | ForEach-Object { $allApps -match $_.AppId} 

 

foreach ($item in $AADAPApp) { 

    $tempApps=Get-AzureADApplicationProxyApplication -ObjectId $item.ObjectId

    If ($tempApps.ExternalUrl -notmatch ".msappproxy.net") 
    
     {
       $AADAPServPrinc[$AADAPApp.IndexOf($item)].DisplayName + " (AppId: " + $AADAPServPrinc[$AADAPApp.IndexOf($item)].AppId+")"; 

       $tempApps | select ExternalUrl,InternalUrl,ExternalAuthenticationType, VerifiedCustomDomainCertificatesMetadata | fl

     }
}  

# Get the list of SSL certificates assigned Azure AD Application Proxy applications


$AADAPServPrinc=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

$allApps=Get-AzureADApplication -Top 100000 

$AADAPApp=$AADAPServPrinc | ForEach-Object { $allApps -match $_.AppId} 

[string[]]$certs=$null

foreach ($item in $AADAPApp) { 

    $tempApps=Get-AzureADApplicationProxyApplication -ObjectId $item.ObjectId

    If ($tempApps.VerifiedCustomDomainCertificatesMetadata -match "class")
     {
       $certs+=$tempApps.VerifiedCustomDomainCertificatesMetadata
     }     
}  

Write-Host ("")
Write-Host ("Number of custom domain apps: " + $certs.Count)
Write-Host ("")
Write-Host ("Used certificates:")
Write-Host ("")

$certs | Sort-Object | Get-Unique 
