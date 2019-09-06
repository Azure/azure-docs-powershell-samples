##########################################################
#  Script to setup custom domain on proxy and portal endpoint
#  of api management service.
###########################################################

$random = (New-Guid).ToString().Substring(0,8)

#Azure specific details
$subscriptionId = "my-azure-subscription-id"

# Api Management service specific details
$apimServiceName = "apim-$random"
$resourceGroupName = "apim-rg-$random"
$location = "Japan East"
$organisation = "Contoso"
$adminEmail = "admin@contoso.com"

# Set the context to the subscription Id where the cluster will be created
Select-AzSubscription -SubscriptionId $subscriptionId

# Create a resource group.
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create the Api Management service. Since the SKU is not specified, it creates a service with Developer SKU. 
New-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -Location $location -Organization $organisation -AdminEmail $adminEmail

# Certificate related details
$proxyHostname = "proxy.contoso.net"
# Certificate containing Common Name CN="proxy.contoso.net" or CN=*.contoso.net
$proxyCertificatePath = "C:\proxycert.pfx"
$proxyCertificatePassword = "certPassword"

$portalHostname = "portal.contoso.net"
# Certificate containing Common Name CN="portal.contoso.net" or CN=*.contoso.net
$portalCertificatePath = "C:\portalcert.pfx"
$portalCertificatePassword = "certPassword"

# Upload the custom ssl certificate to be applied to Proxy endpoint / Api Gateway endpoint
$proxyCertUploadResult = Import-AzApiManagementHostnameCertificate -Name $apimServiceName -ResourceGroupName $resourceGroupName `
                        -HostnameType "Proxy" -PfxPath $proxyCertificatePath -PfxPassword $proxyCertificatePassword

# Upload the custom ssl certificate to be applied to Portal endpoint
$portalCertUploadResult = Import-AzApiManagementHostnameCertificate -Name $apimServiceName -ResourceGroupName $resourceGroupName `
                        -HostnameType "Portal" -PfxPath $portalCertificatePath -PfxPassword $portalCertificatePassword

# Create the HostnameConfiguration object for Portal endpoint
$PortalHostnameConf = New-AzApiManagementHostnameConfiguration -Hostname $proxyHostname -CertificateThumbprint $proxyCertUploadResult.Thumbprint

# Create the HostnameConfiguration object for Proxy endpoint
$ProxyHostnameConf = New-AzApiManagementHostnameConfiguration -Hostname $portalHostname -CertificateThumbprint $portalCertUploadResult.Thumbprint

# Apply the configuration to API Management
Set-AzApiManagementHostnames -Name $apimServiceName -ResourceGroupName $resourceGroupName `
        -PortalHostnameConfiguration $PortalHostnameConf -ProxyHostnameConfiguration $ProxyHostnameConf
