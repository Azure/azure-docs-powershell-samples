# Login-AzureRmAccount
# Set the resource group name and location for your primary server
$primaryresourcegroupname = "myPrimaryResourceGroup-$(Get-Random)"
$primarylocation = "westeurope"
# Set the resource group name and location for your secondary server
$secondaryresourcegroupname = "mySecondaryResourceGroup-$(Get-Random)"
$secondarylocation = "southcentralus"
# Set an admin login and password for your servers
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# Set server names - the logical server names have to be unique in the system
$primaryservername = "primary-server-$(Get-Random)"
$secondaryservername = "secondary-server-$(Get-Random)"
# The sample database name
$databasename = "mySampleDatabase"
# The ip address range that you want to allow to access your servers
$primarystartip = "0.0.0.0"
$primaryendip = "0.0.0.0"
$secondarystartip = "0.0.0.0"
$secondaryendip = "0.0.0.0"




# Create two new resource groups
$primaryresourcegroup = New-AzureRmResourceGroup -Name $primaryresourcegroupname -Location $primarylocation
$secondaryresourcegroup = New-AzureRmResourceGroup -Name $secondaryresourcegroupname -Location $secondarylocation

# Create two new logical servers with a system wide unique server name
$primaryserver = New-AzureRmSqlServer -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -Location $primarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$secondaryserver = New-AzureRmSqlServer -ResourceGroupName $secondaryresourcegroupname `
    -ServerName $secondaryservername `
    -Location $secondarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a blank database with S0 performance level on the primary server
$database = New-AzureRmSqlDatabase  -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -DatabaseName $databasename -RequestedServiceObjectiveName "S0"

# Establish Active Geo-Replication
$database = Get-AzureRmSqlDatabase -DatabaseName $databasename -ResourceGroupName $primaryresourcegroupname -ServerName $primaryservername
$database | New-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName $secondaryresourcegroupname -PartnerServerName $secondaryservername -AllowConnections "All"

# Initiate a planned failover
$database = Get-AzureRmSqlDatabase -DatabaseName $databasename -ResourceGroupName $secondaryresourcegroupname -ServerName $secondaryservername
$database | Set-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName $primaryresourcegroupname -Failover

# Monitor Geo-Replication config and health after failover
$database = Get-AzureRmSqlDatabase -DatabaseName $databasename -ResourceGroupName $secondaryresourcegroupname -ServerName $secondaryservername
$database | Get-AzureRmSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryresourcegroupname -PartnerServerName $primaryservername

# Remove the replication link after the failover
$database = Get-AzureRmSqlDatabase -DatabaseName $databasename -ResourceGroupName $secondaryresourcegroupname -ServerName $secondaryservername
$secondaryLink = $database | Get-AzureRmSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryresourcegroupname -PartnerServerName $primaryservername
$secondaryLink | Remove-AzureRmSqlDatabaseSecondary

# Clean up deployment 
#Remove-AzureRmResourceGroup -ResourceGroupName $primaryresourcegroupname
#Remove-AzureRmResourceGroup -ResourceGroupName $secondaryresourcegroupname