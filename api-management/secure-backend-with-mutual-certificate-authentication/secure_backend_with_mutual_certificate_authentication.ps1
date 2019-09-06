##########################################################
#  Script to setup backend mutual authentication using certificates
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

# Certificate needed for Custom Domain Setup
$certificateFilePath = "<Replace with path to the Certificate to be used for Mutual Authentication>"
$certificatePassword = '<Password used to secure the Certificate>'

# Set the context to the subscription Id where the cluster will be created
Select-AzSubscription -SubscriptionId $subscriptionId

# Create a resource group.
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create the Api Management service. Since the SKU is not specified, it creates a service with Developer SKU. 
New-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -Location $location -Organization $organisation -AdminEmail $adminEmail

# Create the api management context
$context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apimServiceName

# upload the certificate
$cert = New-AzApiManagementCertificate -Context $context -PfxFilePath $certificateFilePath -PfxPassword $certificatePassword

# create an authentication-certificate policy with the thumbprint of the certificate
$apiPolicy = "<policies><inbound><base /><authentication-certificate thumbprint=""" + $cert.Thumbprint + """ /></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>"
$echoApi = Get-AzApiManagementApi -Context $context -Name "Echo API"

# setup Policy at the Product Level. Policies can be applied at entire API Management Service Scope, Api Scope, Product Scope and Api Operation Scope
Set-AzApiManagementPolicy -Context $context  -Policy $apiPolicy -ApiId $echoApi.ApiId

