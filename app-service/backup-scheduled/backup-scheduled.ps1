$webappname="mywebapp$(Get-Random)"
$storagename="$(webappname)storage"
$container="appbackup"
$location="West Europe"

# Create a resource group.
New-AzureRmResourceGroup -Name $webappname -Location $location

# Create a storage account.
$storage = New-AzureRmStorageAccount -ResourceGroupName myResourceGroup `
-Name $storagename -SkuName Standard_LRS -Location $location

# Create a storage container.
New-AzureStorageContainer -Name $container -Context $storage.Context

# Generates an SAS token for the storage container, valid for 1 year.
# NOTE: You can use the same SAS token to make backups in Web Apps until -ExpiryTime
$sasUrl = New-AzureStorageContainerSASToken -Name $container -Permission rwdl `
-Context $storage.Context -ExpiryTime (Get-Date).AddYears(1) -FullUri

# Create an App Service plan in Standard tier. Standard tier allows one backup per day.
New-AzureRmAppServicePlan -Name $webappname -Location $location `
-ResourceGroupName $webappname -Tier Standard

# Create a web app.
New-AzureRmWebApp -Name $webappname -Location $location -AppServicePlan $webappname `
-ResourceGroupName $webappname

# Schedule a backup every day, beginning in one hour, and retain for 10 days
Edit-AzureRmWebAppBackupConfiguration -Name $webappname -ResourceGroupName myResourceGroup `
-StorageAccountUrl $sasUrl -FrequencyInterval 1 -FrequencyUnit Day -KeepAtLeastOneBackup `
-StartTime (Get-Date).AddHours(1) -RetentionPeriodInDays 10

# List statuses of all backups that are complete or currently executing.
Get-AzureRmWebAppBackupList -ResourceGroupName myResourceGroup -Name $webappname

# (OPTIONAL) Change the backup schedule to every 2 days
$configuration = Get-AzureRmWebAppBackupConfiguration -ResourceGroupName myResourceGroup `
-Name $webappname
$configuration.FrequencyInterval = 2
$configuration | Edit-AzureRmWebAppBackupConfiguration