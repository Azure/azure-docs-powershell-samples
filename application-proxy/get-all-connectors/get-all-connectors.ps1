# Get all Azure AD Application Proxy Connector groups with the included connectors

$AADAPConnectorGroups=Get-AzureADApplicationProxyConnectorGroup -Top 100000 

foreach ($item in $AADAPConnectorGroups) {
   
    If ($item.ConnectorGroupType -eq "applicationProxy")
    {
     "Connector group: " + $item.Name 
      Get-AzureADApplicationProxyConnectorGroupMembers -Id $item.Id;
     " ";
    }
}  
