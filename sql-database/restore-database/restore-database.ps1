# Connect-AzAccount
$SubscriptionId = ''
# Set the resource group name and location for your server
$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "westus2"
# Set an admin login and password for your server
$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
# Set server name - the logical server name has to be unique in the system
$serverName = "server-$(Get-Random)"
# The sample database name
$databaseName = "mySampleDatabase"
# The restored database names
$geoRestoreDatabaseName = "MySampleDatabase_GeoRestore"
$pointInTimeRestoreDatabaseName = "MySampleDatabase_10MinutesAgo"
$deletedDatabaseRestoreName = "MySampleDatabase_DeletedRestore"
# The ip address range that you want to allow to access your server
$startIp = "0.0.0.0"
$endIp = "0.0.0.0"

# Set subscription 
Set-AzContext -SubscriptionId $subscriptionId 

# Create a resource group
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a server with a system wide unique server name
$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
$firewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp

# Create a blank database with an S0 performance level
$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName "S0" 

# Restore database from latest geo-redundant backup into existing server 
# Check to see that backups are created and ready to restore from geo-redundant backup (this may take 10-15 minutes)
# Important: If no backup exists, you will get an error indicating that no backups exist for the server specified

Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName 
Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName

# Do not continue until a backup exists

Restore-AzSqlDatabase `
    -FromGeoBackup `
    -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -TargetDatabaseName $geoRestoreDatabaseName `
    -ResourceId $database.ResourceID `
    -Edition "Standard" `
    -ServiceObjectiveName "S0"

# Restore database to its state 10 minutes ago
# Note: Point-in-time restore requires database to be at least 5 minutes old
Restore-AzSqlDatabase `
      -FromPointInTimeBackup `
      -PointInTime (Get-Date).AddMinutes(-10) `
      -ResourceGroupName $resourceGroupName `
      -ServerName $serverName `
      -TargetDatabaseName $pointInTimeRestoreDatabaseName `
      -ResourceId $database.ResourceID `
      -Edition "Standard" `
      -ServiceObjectiveName "S0"

# Delete original database
Remove-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName

# Restore deleted database 
# Note: Check to see that the Get-AzSqlDeletedDatabaseBackup cmdlet returns a deletion date (may take a few minutes). 
# Important: If no backup exists, no value will be returned.
Start-Sleep -Seconds 120
$deleteddatabase = Get-AzSqlDeletedDatabaseBackup -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName
$deleteddatabase
# Do not continue until the cmdlet returns information about the deleted database.
Restore-AzSqlDatabase -FromDeletedDatabaseBackup `
    -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -TargetDatabaseName $deletedDatabaseRestoreName `
    -ResourceId $deleteddatabase.ResourceID `
    -DeletionDate $deleteddatabase.DeletionDate `
    -Edition "Standard" `
    -ServiceObjectiveName "S0"

# Clean up deployment 
# Remove-AzResourceGroup -ResourceGroupName $resourcegroupname