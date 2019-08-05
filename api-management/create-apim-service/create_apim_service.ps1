##########################################################
#  Script to create a Developer SKU API Management Service
#
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

# Get an SSO token to login into the Service
Get-AzApiManagementSsoToken -ResourceGroupName $resourceGroupName -Name $apimServiceName
