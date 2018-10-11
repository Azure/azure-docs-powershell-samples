##########################################################
#  Script to import an API and add it to a Product in api Management 
#  Adding the Imported api to a product is necessary, so that it can be called by a subscription
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

# Api Specific Details
$swaggerUrl = "http://petstore.swagger.io/v2/swagger.json"
$apiPath = "petstore"

# Set the context to the subscription Id where the cluster will be created
Select-AzureRmSubscription -SubscriptionId $subscriptionId

# Create a resource group.
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

# Create the Api Management service. Since the SKU is not specified, it creates a service with Developer SKU. 
New-AzureRmApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -Location $location -Organization $organisation -AdminEmail $adminEmail

# Create the API Management context
$context = New-AzureRmApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apimServiceName

# import api from Url
$api = Import-AzureRmApiManagementApi -Context $context -SpecificationUrl $swaggerUrl -SpecificationFormat Swagger -Path $apiPath

$productName = "Pet Store Product"
$productDescription = "Product giving access to Petstore api"
$productState = "Published"

# Create a Product to publish the Imported Api. This creates a product with a limit of 10 Subscriptions
$product = New-AzureRmApiManagementProduct -Context $context -Title $productName -Description $productDescription -State $productState -SubscriptionsLimit 10 

# Add the petstore api to the published Product, so that it can be called in developer portal console
Add-AzureRmApiManagementApiToProduct -Context $context -ProductId $product.ProductId -ApiId $api.ApiId
