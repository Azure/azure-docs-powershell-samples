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
Select-AzSubscription -SubscriptionId $subscriptionId

# Create a resource group.
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create the Api Management service. Since the SKU is not specified, it creates a service with Developer SKU. 
New-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -Location $location -Organization $organisation -AdminEmail $adminEmail

# Scale master region to 'Premium' 1
$sku = "Premium"
$capacity = 1

# Add new 'Premium' region 1 unit
$additionLocation = Get-ProviderLocations "Microsoft.ApiManagement/service" | Where-Object {$_ -ne $location} | Select-Object -First 1

Get-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName |
Update-AzApiManagementRegion -Sku $sku -Capacity $capacity |
Add-AzApiManagementRegion -Location $additionLocation -Sku $sku |
Update-AzApiManagementDeployment

Get-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName
