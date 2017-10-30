$webappname="mywebapp$(Get-Random -Minimum 100000 -Maximum 999999)"
$storagename="$($webappname)storage"
$container="appbackup"
$location="West Europe"
$backupname="backup1"

# Create a resource group.
New-AzureRmResourceGroup -Name myResourceGroup -Location $location

# Create a storage account.
$storage = New-AzureRmStorageAccount -ResourceGroupName myResourceGroup `
-Name $storagename -SkuName Standard_LRS -Location $location

# Create a storage container.
New-AzureStorageContainer -Name $container -Context $storage.Context

# Generates an SAS token for the storage container, valid for one month.
# NOTE: You can use the same SAS token to make backups in Web Apps until -ExpiryTime
$sasUrl = New-AzureStorageContainerSASToken -Name $container -Permission rwdl `
-Context $storage.Context -ExpiryTime (Get-Date).AddMonths(1) -FullUri

# Create an App Service plan in Standard tier. Standard tier allows one backup per day.
New-AzureRmAppServicePlan -ResourceGroupName myResourceGroup -Name $webappname `
-Location $location -Tier Standard

# Create a web app.
New-AzureRmWebApp -ResourceGroupName myResourceGroup -Name $webappname `
-Location $location -AppServicePlan $webappname

# Create a one-time backup
New-AzureRmWebAppBackup -ResourceGroupName myResourceGroup -Name $webappname `
-StorageAccountUrl $sasUrl -BackupName $backupname

# List statuses of all backups that are complete or currently executing.
Get-AzureRmWebAppBackupList -ResourceGroupName myResourceGroup -Name $webappname