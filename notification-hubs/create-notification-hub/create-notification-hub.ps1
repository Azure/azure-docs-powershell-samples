# Set appropriate values for these variables
$resourceGroupName = "<Enter a name for the resource group>"
$nhubnamespace = "<Enter a name for the notification hub namespace>"
$location = "East US"

# Create a resource group.
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

# Create a namespace for the resource group
New-AzureRmNotificationHubsNamespace -ResourceGroup $resourceGroupName -Namespace $nhubnamespace -Location $location

# Create an input JSON file that you use with the New-AzureRmNotificationHub command
$text = '{"name": "MyNotificationHub",  "Location": "East US",  "Properties": {  }}'
$text | Out-File "inputfile2.json"

# Create a notification hub
New-AzureRmNotificationHub -ResourceGroup $resourceGroupName -Namespace $nhubnamespace -InputFile .\inputfile.json
