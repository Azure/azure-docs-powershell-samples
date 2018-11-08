# Provide the name of the topic you are subscribing to
$myTopic = "demoContosoTopic"

# Provide an endpoint for handling the events.
$myEndpoint = "<endpoint URL>"

# Provide the name of the resource group containing the custom topic.
$myResourceGroup="demoResourceGroup"

# Subscribe to the custom event. Include the resource group that contains the custom topic.
New-AzureRmEventGridSubscription `
  -EventSubscriptionName demoSubscription `
  -Endpoint $myEndpoint `
  -ResourceGroupName $myResourceGroup `
  -TopicName $myTopic
