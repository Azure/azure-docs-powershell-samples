# Connect-AzAccount
$SubscriptionId = ''
# Set the resource group name and location for your primary server
$primaryResourceGroupName = "myPrimaryResourceGroup-$(Get-Random)"
$primaryLocation = "westus2"
# Set the resource group name and location for your secondary server
$secondaryResourceGroupName = "mySecondaryResourceGroup-$(Get-Random)"
$secondaryLocation = "eastus"
# Set an admin login and password for your servers
$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
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
Set-AzContext -SubscriptionId $subscriptionId 

# Create two new resource groups
$primaryResourceGroup = New-AzResourceGroup -Name $primaryResourceGroupName -Location $primaryLocation
$secondaryResourceGroup = New-AzResourceGroup -Name $secondaryResourceGroupName -Location $secondaryLocation

# Create two new logical servers with a system wide unique server name
$primaryServer = New-AzSqlServer -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryServerName `
    -Location $primaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$secondaryServer = New-AzSqlServer -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryServerName `
    -Location $secondaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule for each server that allows access from the specified IP range
$primaryserverfirewallrule = New-AzSqlServerFirewallRule -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $primaryStartIp -EndIpAddress $primaryEndIp
$secondaryserverfirewallrule = New-AzSqlServerFirewallRule -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $secondaryStartIp -EndIpAddress $secondaryEndIp

# Create a blank database with S0 performance level on the primary server
$database = New-AzSqlDatabase  -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryServerName `
    -DatabaseName $databasename -RequestedServiceObjectiveName "S0"

# Establish Active Geo-Replication
$database = Get-AzSqlDatabase -DatabaseName $databasename -ResourceGroupName $primaryResourceGroupName -ServerName $primaryServerName
$database | New-AzSqlDatabaseSecondary -PartnerResourceGroupName $secondaryResourceGroupName -PartnerServerName $secondaryServerName -AllowConnections "All"

# Initiate a planned failover
$database = Get-AzSqlDatabase -DatabaseName $databasename -ResourceGroupName $secondaryResourceGroupName -ServerName $secondaryServerName
$database | Set-AzSqlDatabaseSecondary -PartnerResourceGroupName $primaryResourceGroupName -Failover

# Monitor Geo-Replication config and health after failover
$database = Get-AzSqlDatabase -DatabaseName $databasename -ResourceGroupName $secondaryResourceGroupName -ServerName $secondaryServerName
$database | Get-AzSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryResourceGroupName -PartnerServerName $primaryServerName

# Remove the replication link after the failover
$database = Get-AzSqlDatabase -DatabaseName $databasename -ResourceGroupName $secondaryResourceGroupName -ServerName $secondaryServerName
$secondaryLink = $database | Get-AzSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryResourceGroupName -PartnerServerName $primaryServerName
$secondaryLink | Remove-AzSqlDatabaseSecondary

# Clean up deployment 
#Remove-AzResourceGroup -ResourceGroupName $primaryResourceGroupName
#Remove-AzResourceGroup -ResourceGroupName $secondaryResourceGroupName