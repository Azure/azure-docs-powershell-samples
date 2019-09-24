# Get all Azure AD Application Proxy applications (AppId, Name of the app, ObjID)
 
Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} | fl AppId, DisplayName, ObjectId 

# Get the number of Azure AD Application Proxy applications
 
$AADAPApp=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 
$AADAPApp.Count
 
# Get all Azure AD Application Proxy applications (AppId, Name of the app, external / internal url, authentication type)

$AADAPServPrinc=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 
$allApps=Get-AzureADApplication -Top 100000
$AADAPApp=$AADAPServPrinc | ForEach-Object { $allApps -match $_.AppId}

foreach ($item in $AADAPApp) {
    $AADAPServPrinc[$AADAPApp.IndexOf($item)].DisplayName + " (AppId: " + $AADAPServPrinc[$AADAPApp.IndexOf($item)].AppId+")";
    Get-AzureADApplicationProxyApplication -ObjectId $item.ObjectId | fl ExternalUrl, InternalUrl,ExternalAuthenticationType
}

# Get all Azure AD Application Proxy Connector groups with the assigned applications
 
$AADAPServPrinc=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 
$allApps=Get-AzureADApplication -Top 100000
$AADAPApp=$AADAPServPrinc | ForEach-Object { $allApps -match $_.AppId}
$AADAPConnectorGroups=Get-AzureADApplicationProxyConnectorGroup -Top 100000 


foreach ($item in $AADAPConnectorGroups)
 {
    
   If ($item.ConnectorGroupType -eq "applicationProxy")
    {
     "Connector group: " + $item.Name+ " (Id: " + $item.Id+ ")";
     " ";
     

    foreach ($item2 in $AADAPApp)
     {

      $connector=Get-AzureADApplicationProxyApplicationConnectorGroup -ObjectId $item2.ObjectID;

            If ($item.Id -eq $connector.Id) 
            
            {
            
            $name = $AADAPServPrinc -match $item2.AppId            
            $name.DisplayName + " (AppId: " + $item2.AppId+ ")"}

     }
     " ";
     }
 }   
