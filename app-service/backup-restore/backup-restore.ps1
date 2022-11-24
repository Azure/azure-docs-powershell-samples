$resourceGroupName = "myResourceGroup"
$webappname = "<replace-with-your-app-name>"
$targetResourceGroupName = "myResourceGroup"
$targetWebappName = "<replace-with-your-app-name>"

# List statuses of all backups that are complete or currently executing.
Get-AzWebAppBackupList -ResourceGroupName $resourceGroupName -Name $webappname

# Note the BackupID property of the backup you want to restore

# Get the backup object that you want to restore by specifying the BackupID
$backup = (Get-AzWebAppBackup -ResourceGroupName $resourceGroupName -Name $webappname -BackupId '<replace-with-BackupID>')

# Get the storage account URL of the backup configuration
$url = (Get-AzWebAppBackupConfiguration -ResourceGroupName $resourceGroupName -Name $webappname).StorageAccountUrl

# Restore the app by overwriting it with the backup data
Restore-AzWebAppBackup -ResourceGroupName $resourceGroupName -Name $webappname -StorageAccountUrl $url -BlobName $backup.BlobName -Overwrite
