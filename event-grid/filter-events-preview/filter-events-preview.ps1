# You must have the latest version of the Event Grid PowerShell module.
# To install:
# Install-Module -Name AzureRM.EventGrid -AllowPrerelease -Force -Repository PSGallery

# Provide an endpoint for handling the events. Must be formatted "https://your-endpoint-URL"
$myEndpoint = "<your-endpoint-URL>"

# Provide the name of the custom topic to create
$topicName = "<your-topic-name>"

# Provide the name of the resource group to create. It will contain the custom topic.
$myResourceGroup= "<resource-group-name>"

# Create the resource group
New-AzResourceGroup -Name $myResourceGroup -Location westus2

# Create custom topic
New-AzEventGridTopic -ResourceGroupName $myResourceGroup -Location westus2 -Name $topicName

# Get resource ID of custom topic
$topicid = (Get-AzEventGridTopic -ResourceGroupName $myResourceGroup -Name $topicName).Id

# Set the operator type, field and values for the filtering
$AdvFilter1=@{operator="StringIn"; key="Data.color"; Values=@('blue', 'red', 'green')}

# Subscribe to the custom topic. Filter based on a value in the event data.
New-AzEventGridSubscription `
  -ResourceId $topicid `
  -EventSubscriptionName demoSubWithFilter `
  -Endpoint $myEndpoint `
  -AdvancedFilter @($AdvFilter1)
