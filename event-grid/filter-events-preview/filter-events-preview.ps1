# You must have the latest version of the Event Grid PowerShell module.
# To install:
# Install-Module -Name AzureRM.EventGrid -AllowPrerelease -Force -Repository PSGallery

# Provide an endpoint for handling the events.
$myEndpoint = "<endpoint URL>"

# Provide the name of the custom topic to create
$topicName = "<your-topic-name>"

# Provide the name of the resource group to create. It will contain the custom topic.
$myResourceGroup= "<resource-group>"

# Create the resource group
New-AzureRmResourceGroup -Name $myResourceGroup -Location eastus2

# Create custom topic
New-AzureRmEventGridTopic -ResourceGroupName $myResourceGroup -Location eastus2 -Name $topicName

# Get resource ID of custom topic
$topicid = (Get-AzureRmEventGridTopic -ResourceGroupName $myResourceGroup -Name $topicName).Id

# Set the operator type, field and values for the filtering
$AdvFilter1=@{operator="StringIn"; key="Data.color"; Values=@('blue', 'red', 'green')}

# Subscribe to the custom topic. Filter based on a value in the event data.
New-AzureRmEventGridSubscription `
  -ResourceId $topicid `
  -EventSubscriptionName demoSubWithFilter `
  -Endpoint $endpointURL `
  -AdvancedFilter @($AdvFilter1)
