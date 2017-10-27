$resourceGroupName = "myResourceGroup"
$webappname = "<replace-with-your-app-name>"

# List statuses of all backups that are complete or currently executing.
Get-AzureRmWebAppBackupList -ResourceGroupName myResourceGroup -Name $webappname

# Note the BackupID property of the backup you want to restore

# Get the backup object that you want to restore by specifying the BackupID
$backup = Get-AzureRmWebAppBackup -Name $appName -ResourceGroupName $resourceGroupName `
-BackupId <replace-with-BackupID>

# Restore the app by overwriting it with the backup data
$backup | Restore-AzureRmWebAppBackup -Overwrite