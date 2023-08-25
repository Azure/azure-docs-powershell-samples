# This sample script creates a web app in App Service with its related resources, and then creates a one-time backup for it.
# To run this script, you need an existing backup for a web app. To create one, see Backup up a web app or Create a scheduled backup for a web app.

$resourceGroupName = "myResourceGroup"
$webappname = "<replace-with-your-app-name>"

# List statuses of all backups that are complete or currently executing.
Get-AzWebAppBackupList -ResourceGroupName $resourceGroupName -Name $webappname

# Note the BackupID property of the backup you want to delete

# Delete the backup by specifying the BackupID
Remove-AzWebAppBackup -ResourceGroupName $resourceGroupName -Name $webappname `
-BackupId '<replace-with-BackupID>'
