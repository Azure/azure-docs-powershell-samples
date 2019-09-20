# Get all Azure AD Application Proxy application custom domain applications

$AADAPSERVPRINC=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

$ALLAPPS=Get-AzureADApplication -Top 100000 

$AADAPAPP=$AADAPSERVPRINC | ForEach-Object { $ALLAPPS -match $_.AppId} 

 

foreach ($ITEM in $AADAPAPP) { 

    $TEMPAPPS=Get-AzureADApplicationProxyApplication -ObjectId $ITEM.ObjectId

    If ($TEMPAPPS.ExternalUrl -notmatch ".msappproxy.net") 
    
     {
       $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].DisplayName + " (AppId: " + $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].AppId+")"; 

       $TEMPAPPS | select ExternalUrl,InternalUrl,ExternalAuthenticationType, VerifiedCustomDomainCertificatesMetadata | fl

     }
}  

# Get the list of SSL certificates assigned Azure AD Application Proxy applications


$AADAPSERVPRINC=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

$ALLAPPS=Get-AzureADApplication -Top 100000 

$AADAPAPP=$AADAPSERVPRINC | ForEach-Object { $ALLAPPS -match $_.AppId} 

[string[]]$CERTS=$null

foreach ($ITEM in $AADAPAPP) { 

    $TEMPAPPS=Get-AzureADApplicationProxyApplication -ObjectId $ITEM.ObjectId

    If ($TEMPAPPS.VerifiedCustomDomainCertificatesMetadata -match "class")
     {
       $CERTS+=$TEMPAPPS.VerifiedCustomDomainCertificatesMetadata
     }     
}  

Write-Host ("")
Write-Host ("Number of custom domain apps: " + $CERTS.Count)
Write-Host ("")
Write-Host ("Used certificates:")
Write-Host ("")

$CERTS | Sort-Object | Get-Unique 
