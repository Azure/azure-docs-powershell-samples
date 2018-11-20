# Provide an endpoint for handling the events. Must be formatted "https://your-endpoint-URL"
$myEndpoint = "<endpoint URL>"

# Provide the name of the resource group to create. It will contain the network security group.
# You will subscribe to events for this resource group.
$myResourceGroup = "<resource-group>"

# Create the resource group
New-AzureRmResourceGroup -Name $myResourceGroup -Location westus2

# Create a network security group. You will filter events to only those that are related to this resource.
New-AzureRmNetworkSecurityGroup -Name "nsg1" -ResourceGroupName $myResourceGroup  -Location westus2

# Get the resource ID to filter events
$resourceId = (Get-AzureRmResource -ResourceName "nsg1" -ResourceGroupName $myResourceGroup).ResourceId

# Subscribe to the resource group. Provide the name of the resource group you want to subscribe to.
New-AzureRmEventGridSubscription `
  -Endpoint $myEndpoint `
  -EventSubscriptionName demoSubscriptionToResourceGroup `
  -ResourceGroupName $myResourceGroup `
  -SubjectBeginsWith $resourceId
