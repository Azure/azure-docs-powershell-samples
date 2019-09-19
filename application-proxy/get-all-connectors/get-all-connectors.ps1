# Get all Azure AD Application Proxy Connector groups with the included connectors

$AADAPCONNECTORGROUPS=Get-AzureADApplicationProxyConnectorGroup -Top 100000 

foreach ($ITEM in $AADAPCONNECTORGROUPS) {
   
    If ($ITEM.ConnectorGroupType -eq "applicationProxy")
    {
     "Connector group: " + $ITEM.Name 
      Get-AzureADApplicationProxyConnectorGroupMembers -Id $ITEM.Id;
     " ";
    }
}  
