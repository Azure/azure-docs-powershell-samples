##########################################################
#  Script to apply Rate Limit to Policy at the Product Level 
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
Select-AzureRmSubscription -SubscriptionId $subscriptionId

# Create a resource group.
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

# Create the Api Management service. Since the SKU is not specified, it creates a service with Developer SKU. 
New-AzureRmApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -Location $location -Organization $organisation -AdminEmail $adminEmail

# create a rate-limit product level policy
$productValid = '<policies><inbound><rate-limit calls="5" renewal-period="60" /><quota calls="100" renewal-period="604800" /><base /></inbound><outbound><base /></outbound></policies>'
$product = Get-AzureRmApiManagementProduct -Context $context -Title 'Unlimited' | Select-Object -First 1

# setup Policy at the Product Level. Policies can be applied at entire API Management Service Scope, Api Scope, Product Scope and Api Operation Scope
Set-AzureRmApiManagementPolicy -Context $context  -Policy $productValid -ProductId $product.ProductId -PassThru

