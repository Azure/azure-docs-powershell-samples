# You must have the latest version of the Event Grid PowerShell module.
# To install:
# Install-Module -Name AzureRM.EventGrid -AllowPrerelease -Force -Repository PSGallery

# Provide the name of the topic you are subscribing to
$myTopic = "demoContosoTopic"

# Provide an endpoint for handling the events.
$myEndpoint = "<endpoint URL>"

# Provide the name of the resource group containing the custom topic.
$myResourceGroup = "demoResourceGroup"

# Get the resource ID of the custom topic
$topicID = (Get-AzureRmEventGridTopic -Name $myTopic -ResourceGroupName $myResourceGroup).Id

# Subscribe to the custom event. Include the resource group that contains the custom topic.
New-AzureRmEventGridSubscription `
  -ResourceId $topicID
  -EventSubscriptionName demoSubscription `
  -Endpoint $myEndpoint 