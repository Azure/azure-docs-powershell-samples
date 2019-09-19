# Move all applications assigned to a specific connector group to another connector group


$OLDCONNECTORGROUPID="REPLACE_WITH_THE_OLD_CONNECTOR_GROUP_ID"
$NEWCONNECTORGROUPID="REPLACE_WITH_THE_NEW_CONNECTOR_GROUP_ID"

$AADAPSERVPRINC=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 
$ALLAPPS=Get-AzureADApplication -Top 100000
$AADAPAPP=$AADAPSERVPRINC | ForEach-Object { $ALLAPPS -match $_.AppId}

foreach ($ITEM in $AADAPAPP)
     {

      $CONNECTOR=Get-AzureADApplicationProxyApplicationConnectorGroup -ObjectId $ITEM.ObjectID;

            If ($OLDCONNECTORGROUPID -eq $CONNECTOR.Id) 
            
            {
            
            $NAME = $AADAPSERVPRINC -match $ITEM.AppId            
            $NAME.DisplayName + " (AppId: " + $ITEM.AppId+ ")"
            
            Set-AzureADApplicationProxyApplicationConnectorGroup -ObjectId $ITEM.ObjectId -ConnectorGroupId $NEWCONNECTORGROUPID
            
            }

     } 
