# Provide an endpoint for handling the events.
$myEndpoint = "<endpoint URL>"

# Provide the name of the resource group to subscribe to.
$myResourceGroup="<resource group name>"

# Select the Azure subscription that contains the resource group.
Set-AzureRmContext -Subscription "Contoso Subscription"

# Subscribe to the resource group. Provide the name of the resource group you want to subscribe to.
New-AzureRmEventGridSubscription `
  -Endpoint $myEndpoint `
  -EventSubscriptionName demoSubscriptionToResourceGroup `
  -ResourceGroupName $myResourceGroup