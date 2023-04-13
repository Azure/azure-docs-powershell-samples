##########################################################
#  Script to setup custom domain on proxy and portal endpoint
#  of api management service.
###########################################################


# Api Management service specific details
$apimServiceName = "apim-service-name"
$resourceGroupName = "apim-rg"
$gatewayHostname = "api.contoso.com"                 # API gateway host
$portalHostname = "portal.contoso.com"               # API developer portal host

# Certificate specific details
$gatewayCertCerPath = "C:\Users\Contoso\gateway.cer" # full path to api.contoso.net .cer file
$gatewayCertPfxPath = "C:\Users\Contoso\gateway.pfx" # full path to api.contoso.net .pfx file
$portalCertPfxPath = "C:\Users\Contoso\portal.pfx"   # full path to portal.contoso.net .pfx file
$gatewayCertPfxPassword = "certificatePassword123"   # password for api.contoso.net pfx certificate
$portalCertPfxPassword = "certificatePassword123"    # password for portal.contoso.net pfx certificate

# Convert cert passwords into secure strings
$gatewayCertPfxPasswordSecure = ConvertTo-SecureString -String $gatewayCertPfxPassword -AsPlainText -Force
$portalCertPfxPasswordSecure = ConvertTo-SecureString -String $portalCertPfxPassword -AsPlainText -Force

# Create the HostnameConfiguration object for Proxy endpoint
$proxyHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $gatewayHostname -HostnameType Proxy -PfxPath $gatewayCertPfxPath -PfxPassword $gatewayCertPfxPasswordSecure
# Create the HostnameConfiguration object for Portal endpoint
$portalHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $portalHostname -HostnameType Portal -PfxPath $portalCertPfxPath -PfxPassword $portalCertPfxPasswordSecure

# Get existing API Management instance object
$apim = Get-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName

# Set Proxy and Portal config objects
$apim.ProxyCustomHostnameConfiguration = $proxyHostnameConfig
$apim.PortalCustomHostnameConfiguration = $portalHostnameConfig

# Apply the configuration to API Management
Set-AzApiManagement -InputObject $apim
