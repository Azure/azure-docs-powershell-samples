# Provide a unique name for the Blob storage account.
$storageName = "<your-unique-storage-name>"

# Provide an endpoint for handling the events. Must be formatted "https://your-endpoint-URL"
$myEndpoint = "<your-endpoint-URL>"

# Provide the name of the resource group to create. It will contain the storage account.
$myResourceGroup="<resource-group-name>"

# Create resource group
New-AzResourceGroup -Name $myResourceGroup -Location westus2

# Create the Blob storage account. 
New-AzStorageAccount -ResourceGroupName $myResourceGroup `
  -Name $storageName `
  -Location westus2 `
  -SkuName Standard_LRS `
  -Kind BlobStorage `
  -AccessTier Hot

# Get the resource ID of the Blob storage account.
$storageId = (Get-AzStorageAccount -ResourceGroupName $myResourceGroup -AccountName $storageName).Id

# Subscribe to the Blob storage account. 
New-AzEventGridSubscription `
  -EventSubscriptionName demoSubToStorage `
  -Endpoint $myEndpoint `
  -ResourceId $storageId
