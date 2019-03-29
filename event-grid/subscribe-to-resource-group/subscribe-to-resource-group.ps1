# Provide an endpoint for handling the events. Must be formatted "https://your-endpoint-URL"
$myEndpoint = "<your-endpoint-URL>"

# Provide the name of the resource group to create and subscribe to.
$myResourceGroup="<resource-group-name>"

# Create resource grroup
New-AzResourceGroup -Name $myResourceGroup -Location westus2

# Subscribe to the resource group. Provide the name of the resource group you want to subscribe to.
New-AzEventGridSubscription `
  -Endpoint $myEndpoint `
  -EventSubscriptionName demoSubscriptionToResourceGroup `
  -ResourceGroupName $myResourceGroup
