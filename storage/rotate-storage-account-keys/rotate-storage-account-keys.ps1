# this script will show how to rotate one of the access keys for a storage account

# get list of locations and pick one
Get-AzureRmLocation | select Location

# save the location you want to use  
$location = "eastus"

# create a resource group
$resourceGroup = "rotatekeystestrg"
New-AzureRmResourceGroup -Name $resourceGroup -Location $location 

# create a standard general-purpose storage account 
$storageAccountName = "contosotestkeys"
New-AzureRmStorageAccount -ResourceGroupName $resourceGroup `
  -Name $storageAccountName `
  -Location $location `
  -SkuName Standard_LRS `

# retrieve the first storage account key and display it 
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName).Value[0]

Write-Host "storage account key 1 = " $storageAccountKey

# re-generate the key
New-AzureRmStorageAccountKey -ResourceGroupName $resourceGroup `
    -Name $storageAccountName `
    -KeyName key1

# retrieve it again and display it 
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName).Value[0]
Write-Host "storage account key 1 = " $storageAccountKey
