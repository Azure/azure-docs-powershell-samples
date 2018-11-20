# You must have the latest version of the Event Grid PowerShell module.
# To install:
# Install-Module -Name AzureRM.EventGrid -AllowPrerelease -Force -Repository PSGallery

# Provide an endpoint for handling the events.
$myEndpoint = "<endpoint URL>"

# Provide the name of the resource group to subscribe to.
$myResourceGroup = "<resource group name>"

# Get resource ID of the resource group.
$resourceGroupID = (Get-AzureRmResourceGroup -Name $myResourceGroup).ResourceId

# Subscribe to the resource group. Provide the name of the resource group you want to subscribe to.
New-AzureRmEventGridSubscription `
  -ResourceId $resourceGroupID `
  -Endpoint $myEndpoint `
  -EventSubscriptionName demoSubscriptionToResourceGroup
