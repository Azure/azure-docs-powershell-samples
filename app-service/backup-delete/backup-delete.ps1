$resourceGroupName = "myResourceGroup"
$webappname = "<replace-with-your-app-name>"

# List statuses of all backups that are complete or currently executing.
Get-AzWebAppBackupList -ResourceGroupName $resourceGroupName -Name $webappname

# Note the BackupID property of the backup you want to delete

# Delete the backup by specifying the BackupID
Remove-AzWebAppBackup -ResourceGroupName $resourceGroupName -Name $webappname `
-BackupId <replace-with-BackupID>
