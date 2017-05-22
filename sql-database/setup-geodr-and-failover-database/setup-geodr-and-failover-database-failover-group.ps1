# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server names have to be unique in the system
$primaryresourcegroup = "myPrimaryResourceGroup"
$secondaryresourcegroup = "mySecondaryResourceGroup"
$failovergroupname = "failovergroupname"
$primarylocation = "eastus"
$secondarylocation = "southcentralus"
$primaryservername = "primary-server-$(Get-Random)"
$secondaryservername = "secondary-server-$(Get-Random)"
$databasename = "mySampleDatabase"

# Create two new resource groups
New-AzureRmResourceGroup -Name $primaryresourcegroup -Location $primarylocation

# Create two new logical servers with a system wide unique server name
New-AzureRmSqlServer -ResourceGroupName $primaryresourcegroup `
    -ServerName $primaryservername `
    -Location $primarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
New-AzureRmSqlServer -ResourceGroupName $primaryresourcegroup `
    -ServerName $secondaryservername `
    -Location $secondarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a blank database with S0 performance level on the primary server
New-AzureRmSqlDatabase  -ResourceGroupName $primaryresourcegroup `
    -ServerName $primaryservername `
    -DatabaseName -DatabaseName $databasename -RequestedServiceObjectiveName "S0"

# Create failover group
New-AzureRMSqlDatabaseFailoverGroup `
      –ResourceGroupName $primaryresourcegroup `
      -ServerName $primaryservername `
      -PartnerServerName $secondaryservername  `
      –FailoverGroupName $failovergroupname `
      –FailoverPolicy Automatic `
      -GracePeriodWithDataLossHours 2

# Add database to failover group
Get-AzureRmSqlDatabase `
   -ResourceGroupName $primaryresourcegroup `
   -ServerName $primaryservername `
   -DatabaseName $databasename | `
   Add-AzureRmSqlDatabaseToFailoverGroup `
   -ResourceGroupName $primaryresourcegroup ` `
   -ServerName $primaryservername `
   -FailoverGroupName $failovergroupname

# Initiate a planned failover
Switch-AzureRMSqlDatabaseFailoverGroup `
   -ResourceGroupName $primaryresourcegroup  `
   -ServerName $secondaryservername `
   -FailoverGroupName $failovergroupname 

# Monitor Geo-Replication config and health after failover
Get-AzureRMSqlDatabaseFailoverGroup `
   -ResourceGroupName $primaryresourcegroup  `
   -ServerName $primaryservername 
Get-AzureRMSqlDatabaseFailoverGroup `
   -ResourceGroupName $primaryresourcegroup  `
   -ServerName $secondaryservername 

# Remove the replication link after the failover
Remove-AzureRmSqlDatabaseFailoverGroup `
   -ResourceGroupName $primaryresourcegroup  `
   -ServerName $secondaryservername `
   -FailoverGroupName $failovergroupname

# Clean up deployment 
#Remove-AzureRmResourceGroup -ResourceGroupName $primaryresourcegroup
#Remove-AzureRmResourceGroup -ResourceGroupName $secondaryresourcegroup