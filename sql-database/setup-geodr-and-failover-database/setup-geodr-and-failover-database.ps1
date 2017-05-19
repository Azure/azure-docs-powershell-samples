# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server names have to be unique in the system
$primaryresourcegroup = "myPrimaryResourceGroup"
$secondaryresourcegroup = "mySecondaryResourceGroup"
$primarylocation = "eastus"
$secondarylocation = "southcentralus"
$primaryservername = "primary-server-$(Get-Random)"
$secondaryservername = "secondary-server-$(Get-Random)"

# Create two new resource groups
New-AzureRmResourceGroup -Name $primaryresourcegroup -Location $primarylocation
New-AzureRmResourceGroup -Name $secondaryresourcegroup -Location $secondarylocation

# Create two new logical servers with a system wide unique server name
New-AzureRmSqlServer -ResourceGroupName $primaryresourcegroup `
    -ServerName $primaryservername `
    -Location $primarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
New-AzureRmSqlServer -ResourceGroupName $secondaryresourcegroup `
    -ServerName $secondaryservername `
    -Location $secondarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a blank database with S0 performance level on the primary server
New-AzureRmSqlDatabase  -ResourceGroupName $primaryresourcegroup `
    -ServerName $primaryservername `
    -DatabaseName "mySampleDatabase" -RequestedServiceObjectiveName "S0"

# Establish Active Geo-Replication
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "mySampleDatabase" -ResourceGroupName $primaryresourcegroup -ServerName $primaryservername
$myDatabase | New-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName $secondaryresourcegroup -PartnerServerName $secondaryservername -AllowConnections "All"

# Initiate a planned failover
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "mySampleDatabase" -ResourceGroupName $secondaryresourcegroup -ServerName $secondaryservername
$myDatabase | Set-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName $primaryresourcegroup -Failover

# Monitor Geo-Replication config and health after failover
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "mySampleDatabase" -ResourceGroupName $secondaryresourcegroup -ServerName $secondaryservername
$myDatabase | Get-AzureRmSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryresourcegroup -PartnerServerName $primaryservername

# Remove the replication link after the failover
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "mySampleDatabase" -ResourceGroupName $secondaryresourcegroup -ServerName $secondaryservername
$secondaryLink = $myDatabase | Get-AzureRmSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryresourcegroup -PartnerServerName $primaryservername
$secondaryLink | Remove-AzureRmSqlDatabaseSecondary

# Clean up deployment 
#Remove-AzureRmResourceGroup -ResourceGroupName $primaryresourcegroup
#Remove-AzureRmResourceGroup -ResourceGroupName $secondaryresourcegroup