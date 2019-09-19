# Get all Azure AD Application Proxy applications using custom domain with no certificate

$AADAPSERVPRINC=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

$ALLAPPS=Get-AzureADApplication -Top 100000 

$AADAPAPP=$AADAPSERVPRINC | ForEach-Object { $ALLAPPS -match $_.AppId} 

 

foreach ($ITEM in $AADAPAPP) { 

    $TEMPAPPS=Get-AzureADApplicationProxyApplication -ObjectId $ITEM.ObjectId

    If ($TEMPAPPS.ExternalUrl -notmatch ".msappproxy.net")
     {
     If ($TEMPAPPS.VerifiedCustomDomainCertificatesMetadata -notmatch "class")
      {
       $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].DisplayName + " (AppId: " + $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].AppId+")"; 

       $TEMPAPPS | select ExternalUrl,InternalUrl,ExternalAuthenticationType, VerifiedCustomDomainCertificatesMetadata | fl

      }
     }
}   
