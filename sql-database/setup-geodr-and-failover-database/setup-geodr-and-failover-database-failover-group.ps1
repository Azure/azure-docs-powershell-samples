# Login-AzureRmAccount
# Set the resource group name and location for your primary server
$primaryresourcegroupname = "myPrimaryResourceGroup-$(Get-Random)"
$primarylocation = "eastus"
# Set the resource group name and location for your secondary server
$secondaryresourcegroupname = "mySecondaryResourceGroup-$(Get-Random)"
$secondarylocation = "southcentralus"
# Set an admin login and password for your servers
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# Set failover group name - the failover group name has to be unique in the system
$failovergroupname = "failovergroupname-$(Get-Random)"
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

# Create new resource group
$primaryresourcegroup = New-AzureRmResourceGroup -Name $primaryresourcegroupname -Location $primarylocation

# Create two new logical servers with a system wide unique server name
$primaryserver = New-AzureRmSqlServer -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -Location $primarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$secondaryserver = New-AzureRmSqlServer -ResourceGroupName $secondaryresourcegroupname `
    -ServerName $secondaryservername `
    -Location $secondarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
$primaryserverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $primarystartip -EndIpAddress $primaryendip
$secondaryserverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $secondaryresourcegroupname `
    -ServerName $secondaryservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $secondarystartip -EndIpAddress $secondaryendip
# Create a blank database with S0 performance level on the primary server
$database = New-AzureRmSqlDatabase  -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -DatabaseName $databasename -RequestedServiceObjectiveName "S0"

# Create failover group
$fileovergroup = New-AzureRMSqlDatabaseFailoverGroup `
      –ResourceGroupName $primaryresourcegroupname `
      -ServerName $primaryservername `
      -PartnerServerName $secondaryservername  `
      –FailoverGroupName $failovergroupname `
      –FailoverPolicy Automatic `
      -GracePeriodWithDataLossHours 2

# Add database to failover group
$fileovergroup = Get-AzureRmSqlDatabase `
   -ResourceGroupName $primaryresourcegroupname `
   -ServerName $primaryservername `
   -DatabaseName $databasename | `
   Add-AzureRmSqlDatabaseToFailoverGroup `
   -ResourceGroupName $primaryresourcegroupname ` `
   -ServerName $primaryservername `
   -FailoverGroupName $failovergroupname

# Initiate a planned failover
Switch-AzureRMSqlDatabaseFailoverGroup `
   -ResourceGroupName $primaryresourcegroupname  `
   -ServerName $secondaryservername `
   -FailoverGroupName $failovergroupname 

# Monitor Geo-Replication config and health after failover
Get-AzureRMSqlDatabaseFailoverGroup `
   -ResourceGroupName $primaryresourcegroupname  `
   -ServerName $primaryservername 
Get-AzureRMSqlDatabaseFailoverGroup `
   -ResourceGroupName $primaryresourcegroupname  `
   -ServerName $secondaryservername 

# Remove the replication link after the failover
Remove-AzureRmSqlDatabaseFailoverGroup `
   -ResourceGroupName $primaryresourcegroupname  `
   -ServerName $secondaryservername `
   -FailoverGroupName $failovergroupname

# Clean up deployment 
#Remove-AzureRmResourceGroup -ResourceGroupName $primaryresourcegroupname
#Remove-AzureRmResourceGroup -ResourceGroupName $secondaryresourcegroupname