# Give your custom topic a unique name
$myTopic = "demoContosoTopic"

# Provice name for resource group
$myResourceGroup=demoResourceGroup

# Create resource group
New-AzureRmResourceGroup -Name $myResourceGroup -Location westus2

# Create custom topic
New-AzureRmEventGridTopic -ResourceGroupName $myResourceGroup -Name $myTopic -Location westus2 

# Retrieve endpoint and key to use when publishing to the topic
$endpoint = (Get-AzureRmEventGridTopic -ResourceGroupName $myResourceGroup -Name $myTopic).Endpoint
$key = (Get-AzureRmEventGridTopicKey -ResourceGroupName $myResourceGroup3 -Name $myTopic).Key1

$endpoint
$key