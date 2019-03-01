# Connect-AzAccount
$SubscriptionId = ''
# Set the resource group name and location for your primary server
$ResourceGroupName = "myResourceGroup-$(Get-Random)"
$primaryLocation = "westus2"
# Set the resource group name and location for your secondary server
$secondaryLocation = "East US"
# Set an admin login and password for your servers
$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
# Set failover group name - the failover group name has to be unique in the system
$failoverGroupName = "fog-$(Get-Random)"
# Set server names - the logical server names have to be unique in the system
$primaryServerName = "primary-server-$(Get-Random)"
$secondaryServerName = "secondary-server-$(Get-Random)"
# The sample database name
$databasename = "mySampleDatabase"
# The ip address range that you want to allow to access your servers
$primaryStartIp = "0.0.0.0"
$primaryEndIp = "0.0.0.0"
$secondaryStartIp = "0.0.0.0"
$secondaryEndIp = "0.0.0.0"

# Set subscription 
Set-AzContext -Subscription $subscriptionId 

# Create new resource group
$primaryresourcegroup = New-AzResourceGroup -Name $ResourceGroupName -Location $primaryLocation

# Create two new logical servers with a system wide unique server name
$primaryserver = New-AzSqlServer -ResourceGroupName $ResourceGroupName `
    -ServerName $primaryServerName `
    -Location $primaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

$secondaryserver = New-AzSqlServer -ResourceGroupName $ResourceGroupName `
    -ServerName $secondaryServerName `
    -Location $secondaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
$primaryserverfirewallrule = New-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName `
    -ServerName $primaryServerName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $primaryStartIp -EndIpAddress $primaryEndIp

$secondaryserverfirewallrule = New-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName `
    -ServerName $secondaryServerName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $secondaryStartIp -EndIpAddress $secondaryEndIp

# Create a blank database with S0 performance level on the primary server
$database = New-AzSqlDatabase  -ResourceGroupName $ResourceGroupName `
    -ServerName $primaryServerName `
    -DatabaseName $databasename -RequestedServiceObjectiveName "S0"

# Create failover group
$failoverGroup = New-AzSqlDatabaseFailoverGroup `
      –ResourceGroupName $ResourceGroupName `
      -ServerName $primaryServerName `
      -PartnerServerName $secondaryServerName  `
      –FailoverGroupName $failoverGroupName `
      –FailoverPolicy Automatic `
      -GracePeriodWithDataLossHours 2

# Add database to failover group
$failoverGroup = Get-AzSqlDatabase `
   -ResourceGroupName $ResourceGroupName `
   -ServerName $primaryServerName `
   -DatabaseName $databasename | `
   Add-AzSqlDatabaseToFailoverGroup `
   -ResourceGroupName $ResourceGroupName ` `
   -ServerName $primaryServerName `
   -FailoverGroupName $failoverGroupName

# Initiate a planned failover
Switch-AzSqlDatabaseFailoverGroup `
   -ResourceGroupName $ResourceGroupName  `
   -ServerName $secondaryServerName `
   -FailoverGroupName $failoverGroupName 

# Monitor Geo-Replication config and health after failover
Get-AzSqlDatabaseFailoverGroup `
   -ResourceGroupName $ResourceGroupName  `
   -ServerName $primaryServerName 
Get-AzSqlDatabaseFailoverGroup `
   -ResourceGroupName $ResourceGroupName  `
   -ServerName $secondaryServerName 

# Remove the replication link after the failover
Remove-AzSqlDatabaseFailoverGroup `
   -ResourceGroupName $ResourceGroupName  `
   -ServerName $secondaryServerName `
   -FailoverGroupName $failoverGroupName

# Clean up deployment 
# Remove-AzResourceGroup -ResourceGroupName $ResourceGroupName
