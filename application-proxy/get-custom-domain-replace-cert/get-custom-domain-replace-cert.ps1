# Get all Azure AD Application Proxy applications published with the identical certificate

$CERTTHUMBPRINT="REPLACE_WITH_THE_THUMPRINT_OF_THE_CERTIFICATE"

$AADAPSERVPRINC=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

$ALLAPPS=Get-AzureADApplication -Top 100000 

$AADAPAPP=$AADAPSERVPRINC | ForEach-Object { $ALLAPPS -match $_.AppId} 

 

foreach ($ITEM in $AADAPAPP) { 

    $TEMPAPPS=Get-AzureADApplicationProxyApplication -ObjectId $ITEM.ObjectId

    If ($TEMPAPPS.VerifiedCustomDomainCertificatesMetadata -match $CERTTHUMBPRINT) 
    
     {
       $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].DisplayName + " (AppId: " + $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].AppId+")"; 

       $TEMPAPPS | select ExternalUrl,InternalUrl,ExternalAuthenticationType | fl

     }
}  
 
# Get all the Azure AD Application Proxy applications published with the identical certificate and replace it with a new one

$CERTTHUMBPRINT="REPLACE_WITH_THE_THUMPRINT_OF_THE_CERTIFICATE"
$PFXFILEPATH = "REPLACE_WITH_THE_PATH_TO_THE_PFX_FILE"
$SECUREPASSWORD = Read-Host -AsSecureString // please provide the password of the pfx file


$AADAPSERVPRINC=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

$ALLAPPS=Get-AzureADApplication -Top 100000 

$AADAPAPP=$AADAPSERVPRINC | ForEach-Object { $ALLAPPS -match $_.AppId} 

 

foreach ($ITEM in $AADAPAPP) 
{ 

    $TEMPAPPS=Get-AzureADApplicationProxyApplication -ObjectId $ITEM.ObjectId

    Write-Host ("")
    Write-Host ("SSL certificate change for the Azure AD Application Proxy apps below:")
    Write-Host ("")

    If ($TEMPAPPS.VerifiedCustomDomainCertificatesMetadata -match $CERTTHUMBPRINT) 
    
     {
       $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].DisplayName + " (AppId: " + $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].AppId+")"; 

       $TEMPAPPS | select ExternalUrl,InternalUrl,ExternalAuthenticationType | fl

       Set-AzureADApplicationProxyApplicationCustomDomainCertificate -ObjectId  $ITEM.ObjectId -PfxFilePath $PFXFILEPATH -Password $SECUREPASSWORD

     }
}

Write-Host ("")
Write-Host ("Finished.")
Write-Host ("") 
