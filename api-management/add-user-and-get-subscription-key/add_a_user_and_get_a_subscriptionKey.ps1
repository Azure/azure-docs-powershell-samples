##########################################################
#  Script to create a user in api management and get a subscription key
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

# User specific details
$userEmail = "user@contoso.com"
$userFirstName = "userFirstName"
$userLastName = "userLastName"
$userPassword = "userPassword"
$userNote = "fellow trying out my apim instance"
$userState = "Active"

# Subscription Name details
$subscriptionName = "subscriptionName"
$subscriptionState = "Active"

# Set the context to the subscription Id where the cluster will be created
Select-AzSubscription -SubscriptionId $subscriptionId

# Create a resource group.
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create the Api Management service. Since the SKU is not specified, it creates a service with Developer SKU. 
New-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -Location $location -Organization $organisation -AdminEmail $adminEmail

# Create the api management context
$context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apimServiceName

# create a new user in api management
$user = New-AzApiManagementUser -Context $context -FirstName $userFirstName -LastName $userLastName `
    -Password $userPassword -State $userState -Note $userNote -Email $userEmail

# get the details of the 'Starter' product in api management, which is created by default
$product = Get-AzApiManagementProduct -Context $context -Title 'Starter' | Select-Object -First 1

# generate a subscription key for the user to call apis which are part of the 'Starter' product
New-AzApiManagementSubscription -Context $context -UserId $user.UserId `
    -ProductId $product.ProductId -Name $subscriptionName -State $subscriptionState

