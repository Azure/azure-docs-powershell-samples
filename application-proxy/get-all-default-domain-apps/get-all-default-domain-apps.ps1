# Get all Azure AD Application Proxy application non-custom domain apps (.msappproxy.net)

$AADAPSERVPRINC=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

$ALLAPPS=Get-AzureADApplication -Top 100000 

$AADAPAPP=$AADAPSERVPRINC | ForEach-Object { $ALLAPPS -match $_.AppId} 

 

foreach ($ITEM in $AADAPAPP) { 

    $TEMPAPPS=Get-AzureADApplicationProxyApplication -ObjectId $ITEM.ObjectId

    If ($TEMPAPPS.ExternalUrl -match ".msappproxy.net") 
    
     {
       $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].DisplayName + " (AppId: " + $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].AppId+")"; 

       $TEMPAPPS | select ExternalUrl,InternalUrl,ExternalAuthenticationType | fl

     }
}  
