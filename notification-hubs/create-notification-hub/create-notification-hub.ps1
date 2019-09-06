# Set appropriate values for these variables
$resourceGroupName = "<Enter a name for the resource group>"
$nhubnamespace = "<Enter a name for the notification hub namespace>"
$location = "East US"

# Create a resource group.
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a namespace for the resource group
New-AzNotificationHubsNamespace -ResourceGroup $resourceGroupName -Namespace $nhubnamespace -Location $location

# Create an input JSON file that you use with the New-AzNotificationHub command
$text = '{"name": "MyNotificationHub",  "Location": "East US",  "Properties": {  }}'
$text | Out-File "inputfile2.json"

# Create a notification hub
New-AzNotificationHub -ResourceGroup $resourceGroupName -Namespace $nhubnamespace -InputFile .\inputfile.json
