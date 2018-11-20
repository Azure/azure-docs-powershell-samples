# Provide an endpoint for handling the events. Must be formatted "https://your-endpoint-URL"
$myEndpoint = "<your-endpoint-URL>"

# Provide the name of the resource group to create. It will contain the network security group.
# You will subscribe to events for this resource group.
$myResourceGroup = "<resource-group-name>"

# Provide a name for the network security group to create.
$nsgName = "<your-nsg-name>"

# Create the resource group
New-AzureRmResourceGroup -Name $myResourceGroup -Location westus2

# Create a network security group. You will filter events to only those that are related to this resource.
New-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $myResourceGroup  -Location westus2

# Get the resource ID to filter events
$resourceId = (Get-AzureRmResource -ResourceName $nsgName -ResourceGroupName $myResourceGroup).ResourceId

# Subscribe to the resource group. Provide the name of the resource group you want to subscribe to.
New-AzureRmEventGridSubscription `
  -Endpoint $myEndpoint `
  -EventSubscriptionName demoSubscriptionToResourceGroup `
  -ResourceGroupName $myResourceGroup `
  -SubjectBeginsWith $resourceId
