# Get all Azure AD Application Proxy applications (AppId, Name of the app, ObjID)
 
Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} | fl AppId, DisplayName, ObjectId 

# Get the number of Azure AD Application Proxy applications
 
$AADAPAPP=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 
$AADAPAPP.Count
 
# Get all Azure AD Application Proxy applications (AppId, Name of the app, external / internal url, authentication type)

$AADAPSERVPRINC=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 
$ALLAPPS=Get-AzureADApplication -Top 100000
$AADAPAPP=$AADAPSERVPRINC | ForEach-Object { $ALLAPPS -match $_.AppId}

foreach ($ITEM in $AADAPAPP) {
    $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].DisplayName + " (AppId: " + $AADAPSERVPRINC[$AADAPAPP.IndexOf($ITEM)].AppId+")";
    Get-AzureADApplicationProxyApplication -ObjectId $ITEM.ObjectId | fl ExternalUrl, InternalUrl,ExternalAuthenticationType
}

# Get all Azure AD Application Proxy Connector groups with the assigned applications
 
$AADAPSERVPRINC=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 
$ALLAPPS=Get-AzureADApplication -Top 100000
$AADAPAPP=$AADAPSERVPRINC | ForEach-Object { $ALLAPPS -match $_.AppId}
$AADAPCONNECTORGROUPS=Get-AzureADApplicationProxyConnectorGroup -Top 100000 


foreach ($ITEM in $AADAPCONNECTORGROUPS)
 {
    
   If ($ITEM.ConnectorGroupType -eq "applicationProxy")
    {
     "Connector group: " + $ITEM.Name+ " (Id: " + $ITEM.Id+ ")";
     " ";
     

    foreach ($ITEM2 in $AADAPAPP)
     {

      $CONNECTOR=Get-AzureADApplicationProxyApplicationConnectorGroup -ObjectId $ITEM2.ObjectID;

            If ($ITEM.Id -eq $CONNECTOR.Id) 
            
            {
            
            $NAME = $AADAPSERVPRINC -match $ITEM2.AppId            
            $NAME.DisplayName + " (AppId: " + $ITEM2.AppId+ ")"}

     }
     " ";
     }
 }   
