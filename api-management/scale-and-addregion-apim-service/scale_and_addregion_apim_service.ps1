##########################################################
#  Script to create an apim service and scale to premium 
#  with an additional region.
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

# Scale master region to 'Premium' 1
$sku = "Premium"
$capacity = 1

# Add new 'Premium' region 1 unit
$additionLocation = Get-ProviderLocations "Microsoft.ApiManagement/service" | Where-Object {$_ -ne $location} | Select-Object -First 1

Get-AzureRmApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName |
Update-AzureRmApiManagementRegion -Sku $sku -Capacity $capacity |
Add-AzureRmApiManagementRegion -Location $additionLocation -Sku $sku |
Update-AzureRmApiManagementDeployment

Get-AzureRmApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName