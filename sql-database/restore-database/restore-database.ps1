# Sign in
# Login-AzureRmAccount


# Creat a new resource group
New-AzureRmResourceGroup -Name "SampleResourceGroup" -Location "northcentralus"

# Create a new server with a system wide unique tmp-name
New-AzureRmSqlServer -ResourceGroupName "SampleResourceGroup" `
    -ServerName "tmp-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ServerAdmin", $(ConvertTo-SecureString -String "ASecureP@assw0rd" -AsPlainText -Force))


# Create a blank database with S0 performance level
New-AzureRmSqlDatabase  -ResourceGroupName "SampleResourceGroup" `
    -ServerName "tmp-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -RequestedServiceObjectiveName "S0"

# Restore database from latest geo-redundant backup into existing server 
$GeoBackup = Get-AzureRmSqlDatabaseGeoBackup -ResourceGroupName "SampleResourceGroup" -ServerName "tmp-$($(Get-AzureRMContext).Subscription.SubscriptionId)" -DatabaseName "MySampleDatabase"
Restore-AzureRmSqlDatabase -FromGeoBackup `
    -ResourceGroupName "SampleResourceGroup" `
    -ServerName "tmp-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -TargetDatabaseName "MySampleDatabase_GeoRestore" `
    -ResourceId $GeoBackup.ResourceID `
    -Edition "Standard" `
    -ServiceObjectiveName "S0"

# Restore database to its state 10 minutes ago
# Note: Point-in-time restore requires database to be at least 5 minutes old
# Restore-AzureRmSqlDatabase -FromPointInTimeBackup `
#      -PointInTime (Get-Date).AddMinutes(-10) `
#      -ResourceGroupName "SampleResourceGroup" `
#      -ServerName "tmp-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
#      -TargetDatabaseName "MySampleDatabase_10MinutesAgo" `
#      -ResourceId $(Get-AzureRmSqlDatabase -ResourceGroupName "SampleResourceGroup" -ServerName "tmp-$($(Get-AzureRMContext).Subscription.SubscriptionId)" -DatabaseName "MySampleDatabase_DeletedRestore").ResourceID `
#      -Edition "Standard" `
#      -ServiceObjectiveName "S0"

# Delete original database
Remove-AzureRmSqlDatabase -ResourceGroupName "SampleResourceGroup" -ServerName "tmp-$($(Get-AzureRMContext).Subscription.SubscriptionId)" -DatabaseName "MySampleDatabase"

# Restore deleted database 
$deletedDatabase = Get-AzureRmSqlDeletedDatabaseBackup -ResourceGroupName "SampleResourceGroup" -ServerName "tmp-$($(Get-AzureRMContext).Subscription.SubscriptionId)" -DatabaseName "MySampleDatabase"
Restore-AzureRmSqlDatabase -FromDeletedDatabaseBackup `
    -ResourceGroupName "SampleResourceGroup" `
    -ServerName "tmp-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -TargetDatabaseName "MySampleDatabase_DeletedRestore" `
    -ResourceId $deletedDatabase.ResourceID `
    -DeletionDate $deletedDatabase.DeletionDate `
    -Edition "Standard" `
    -ServiceObjectiveName "S0"


# Cleanup: Delete the resource group and ALL resources in it
# Remove-AzureRmResourceGroup -ResourceGroupName "SampleResourceGroup"