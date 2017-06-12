# this script will show how to delete containers with a specific prefix 
# the prefix this will search for is "Image". 
# before running this, you need to create a storage account, create a container,
#    and upload some blobs into the container 
# note: this retrieves all of the matching blobs in one command 
#       if you are going to run this against a container with a lot of blobs
#       (more than a couple hundred), use continuation tokens to retrieve
#       the list of blobs. We will be adding a sample showing that scenario in the future.

# login to your Azure account
Login-AzureRmAccount

# these are for the storage account to be used
#   and the prefix for which to search
$resourceGroup = "bloblisttestrg"
$location = "westus"
$storageAccountName = "contosobloblisttest"
$containerName = "listtestblobs"
$prefix = "Image"

# get a reference to the storage account and the context
$storageAccount = Get-AzureRmStorageAccount `
  -ResourceGroupName $resourceGroup `
  -Name $storageAccountName
$ctx = $storageAccount.Context 

# list all blobs in the container
Write-Host "All blobs"
Get-AzureStorageBlob -Container $ContainerName -Context $ctx | select Name

# retrieve list of blobs to delete
$listOfBlobsToDelete = Get-AzureStorageBlob -Container $ContainerName -Context $ctx -Prefix $prefix 

# write list of blobs to be deleted 
Write-Host "Blobs to be deleted"
$listOfBlobsToDelete | select Name, Length

# delete the blobs
Write-Host "Deleting blobs"
$listOfBlobsToDelete | ForEach-Object { Remove-AzureStorageBlob -Container $containerName -Context $ctx -Blob $_.Name}

# show list of blobs not deleted 
Write-Host "All Blobs not deleted"
Get-AzureStorageBlob -Container $containerName -Context $ctx | select Name
