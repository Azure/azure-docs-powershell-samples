# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server name has to be unique in the system
$servername = "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"

# Create a new resource group
New-AzureRmResourceGroup -Name "myResourceGroup" -Location "northcentralus"

# Create a new server with a system wide unique tmp-name
New-AzureRmSqlServer -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a blank database with S0 performance level
New-AzureRmSqlDatabase  -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "MySampleDatabase" `
    -RequestedServiceObjectiveName "S0"

# Restore database from latest geo-redundant backup into existing server 
$GeoBackup = Get-AzureRmSqlDatabaseGeoBackup -ResourceGroupName "myResourceGroup" -ServerName $servername -DatabaseName "MySampleDatabase"
Restore-AzureRmSqlDatabase -FromGeoBackup `
    -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -TargetDatabaseName "MySampleDatabase_GeoRestore" `
    -ResourceId $GeoBackup.ResourceID `
    -Edition "Standard" `
    -ServiceObjectiveName "S0"

# Restore database to its state 10 minutes ago
# Note: Point-in-time restore requires database to be at least 5 minutes old
# Restore-AzureRmSqlDatabase -FromPointInTimeBackup `
#      -PointInTime (Get-Date).AddMinutes(-10) `
#      -ResourceGroupName "myResourceGroup" `
#      -ServerName $servername `
#      -TargetDatabaseName "MySampleDatabase_10MinutesAgo" `
#      -ResourceId $(Get-AzureRmSqlDatabase -ResourceGroupName "myResourceGroup" -ServerName $servername -DatabaseName "MySampleDatabase_DeletedRestore").ResourceID `
#      -Edition "Standard" `
#      -ServiceObjectiveName "S0"

# Delete original database
Remove-AzureRmSqlDatabase -ResourceGroupName "myResourceGroup" -ServerName $servername -DatabaseName "MySampleDatabase"

# Restore deleted database 
$deletedDatabase = Get-AzureRmSqlDeletedDatabaseBackup -ResourceGroupName "myResourceGroup" -ServerName $servername -DatabaseName "MySampleDatabase"
Restore-AzureRmSqlDatabase -FromDeletedDatabaseBackup `
    -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -TargetDatabaseName "MySampleDatabase_DeletedRestore" `
    -ResourceId $deletedDatabase.ResourceID `
    -DeletionDate $deletedDatabase.DeletionDate `
    -Edition "Standard" `
    -ServiceObjectiveName "S0"
