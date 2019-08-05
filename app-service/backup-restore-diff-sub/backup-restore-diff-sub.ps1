$resourceGroupNameSub1 = "<replace-with-your-group-name>"
$resourceGroupNameSub2 = "<replace-with-desired-new-group-name>"
$webAppNameSub1 = "<replace-with-your-app-name>"
$webAppNameSub2 = "<replace-with-desired-new-app-name>"
$appServicePlanSub2 = "<replace-with-desired-new-plan-name>"
$locationSub2 = "West Europe"


# Log into the subscription with the backup
Add-AzAccount

# List statuses of all backups that are complete or currently executing.
Get-AzWebAppBackupList -ResourceGroupName $resourceGroupNameSub1 -Name $webAppNameSub1

# Note the BackupID property of the backup you want to restore

# Get the backup object that you want to restore by specifying the BackupID
$backup = (Get-AzWebAppBackupList -ResourceGroupName $resourceGroupNameSub1 -Name $webAppNameSub1 | where {$_.BackupId -eq <replace-with-BackupID>}) 

# Log into the subscription that you want to restore the app to
Add-AzAccount

# Create a new web app
New-AzWebApp -ResourceGroupName $resourceGroupNameSub2 -AppServicePlan $appServicePlanSub2 -Name $webAppNameSub2 -Location $locationSub2

# Restore the app by overwriting it with the backup data
Restore-AzWebAppBackup -ResourceGroupName $resourceGroupNameSub2 -Name $webAppNameSub2 -StorageAccountUrl $backup.StorageAccountUrl -BlobName $backup.BlobName -Overwrite
