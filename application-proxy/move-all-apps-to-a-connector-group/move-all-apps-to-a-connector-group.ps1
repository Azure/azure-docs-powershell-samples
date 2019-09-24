# Move all applications assigned to a specific connector group to another connector group


$oldConnectorGroupId="REPLACE_WITH_THE_OLD_CONNECTOR_GROUP_ID"
$newConnectorGroupId="REPLACE_WITH_THE_NEW_CONNECTOR_GROUP_ID"

$AADAPServPrinc=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 
$allApps=Get-AzureADApplication -Top 100000
$AADAPApp=$AADAPServPrinc | ForEach-Object { $allApps -match $_.AppId}

foreach ($item in $AADAPApp)
     {

      $connector=Get-AzureADApplicationProxyApplicationConnectorGroup -ObjectId $item.ObjectID;

            If ($oldConnectorGroupId -eq $connector.Id) 
            
            {
            
            $name = $AADAPServPrinc -match $item.AppId            
            $name.DisplayName + " (AppId: " + $item.AppId+ ")"
            
            Set-AzureADApplicationProxyApplicationConnectorGroup -ObjectId $item.ObjectId -ConnectorGroupId $newConnectorGroupId
            
            }

     } 
