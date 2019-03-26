# You must have the latest version of the Event Grid PowerShell module.
# To install:
# Install-Module -Name AzureRM.EventGrid -AllowPrerelease -Force -Repository PSGallery

# Provide an endpoint for handling the events. Must be formatted "https://your-endpoint-URL"
$myEndpoint = "<your-endpoint-URL>"

# Provide the name of the resource group to create and subscribe to.
$myResourceGroup = "<resource-group-name>"

# Create resource group
$resourceGroupID = (New-AzResourceGroup -Name $myResourceGroup -Location westus2).ResourceId

# Subscribe to the resource group. Provide the name of the resource group you want to subscribe to.
New-AzEventGridSubscription `
  -ResourceId $resourceGroupID `
  -Endpoint $myEndpoint `
  -EventSubscriptionName demoSubscriptionToResourceGroup
