# Login-AzureRmAccount
# Set the resource group name and location for your server
$resourcegroupname = "myResourceGroup-$(Get-Random)"
$location = "westeurope"
# Set an admin login and password for your server
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# Set server name - the logical server name has to be unique in the system
$servername = "server-$(Get-Random)"
# The sample database name
$databasename = "mySampleDatabase"
# The restored database names
$georestoredatabasename = "MySampleDatabase_GeoRestore"
$pointintimerestoredatabasename = "MySampleDatabase_10MinutesAgo"
$deleteddatabaserestorename = "MySampleDatabase_DeletedRestore"
# The ip address range that you want to allow to access your server
$startip = "0.0.0.0"
$endip = "0.0.0.0"


# Create a resource group
$resourcegroup = New-AzureRmResourceGroup -Name $resourcegroupname -Location $location

# Create a server with a system wide unique server name
$server = New-AzureRmSqlServer -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
$firewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startip -EndIpAddress $endip

# Create a blank database with an S0 performance level
$database = New-AzureRmSqlDatabase  -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -DatabaseName $databasename `
    -RequestedServiceObjectiveName "S0" 

# Restore database from latest geo-redundant backup into existing server 
# Note: Check to see that backups are created and ready to restore from geo-redundant backup
# Important: If no backup exists, you will get an error indicating that no backups exist for the server specified
Get-AzureRmSqlDatabaseGeoBackup -ResourceGroupName $resourcegroupname -ServerName $servername 
Get-AzureRmSqlDatabaseGeoBackup -ResourceGroupName $resourcegroupname -ServerName $servername -DatabaseName $databasename
# Do not continue until a backup exists
Restore-AzureRmSqlDatabase `
    -FromGeoBackup `
    -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -TargetDatabaseName $georestoredatabasename `
    -ResourceId $database.ResourceID `
    -Edition "Standard" `
    -ServiceObjectiveName "S0"

# Restore database to its state 10 minutes ago
# Note: Point-in-time restore requires database to be at least 5 minutes old
Restore-AzureRmSqlDatabase `
      -FromPointInTimeBackup `
      -PointInTime (Get-Date).AddMinutes(-10) `
      -ResourceGroupName $resourcegroupname `
      -ServerName $servername `
      -TargetDatabaseName $pointintimerestoredatabasename `
      -ResourceId $database.ResourceID `
      -Edition "Standard" `
      -ServiceObjectiveName "S0"

# Delete original database
Remove-AzureRmSqlDatabase -ResourceGroupName $resourcegroupname -ServerName $servername -DatabaseName $databasename

# Restore deleted database 
# Note: Check to see that the Get-AzureRmSqlDeletedDatabaseBackup cmdlet returns a deletion date (may take a few minutes). 
# Important: If no backup exists, no value will be returned.
$deleteddatabase = Get-AzureRmSqlDeletedDatabaseBackup -ResourceGroupName $resourcegroupname -ServerName $servername -DatabaseName $databasename
$deleteddatabase
# Do not continue until the cmdlet returns information about the deleted database.
Restore-AzureRmSqlDatabase -FromDeletedDatabaseBackup `
    -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -TargetDatabaseName $deleteddatabaserestorename `
    -ResourceId $deleteddatabase.ResourceID `
    -DeletionDate $deleteddatabase.DeletionDate `
    -Edition "Standard" `
    -ServiceObjectiveName "S0"

# Clean up deployment 
# Remove-AzureRmResourceGroup -ResourceGroupName $resourcegroupname