# You must have the latest version of the Event Grid PowerShell module.
# To install:
# Install-Module -Name AzureRM.EventGrid -AllowPrerelease -Force -Repository PSGallery

# Provide the name of the topic you are subscribing to
$myTopic = "<your-custom-topic-name>"

# Provide an endpoint for handling the events. Must be formatted "https://your-endpoint-URL"
$myEndpoint = "<your-endpoint-URL>"

# Provide the name of the resource group to create. It will contain the custom topic.
$myResourceGroup = "<resource-group-name>"

# Create resource group
New-AzResourceGroup -Name $myResourceGroup -Location westus2

# Create custom topic and get its resource ID.
$topicID = (New-AzEventGridTopic -ResourceGroupName $myResourceGroup -Name $myTopic -Location westus2).Id 

# Subscribe to the custom event. Include the resource group that contains the custom topic.
New-AzEventGridSubscription `
  -ResourceId $topicID `
  -EventSubscriptionName demoSubscription `
  -Endpoint $myEndpoint 
