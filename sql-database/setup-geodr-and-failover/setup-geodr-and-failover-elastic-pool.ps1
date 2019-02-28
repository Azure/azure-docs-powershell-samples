# Connect-AzAccount
$SubscriptionId = ''
# Set the resource group name and location for your serverw
$primaryResourceGroupName = "myPrimaryResourceGroup-$(Get-Random)"
$secondaryResourceGroupName = "mySecondaryResourceGroup-$(Get-Random)"
$primaryLocation = "West US"
$secondaryLocation = "East US"
# The logical server names have to be unique in the system
$primaryservername = "primary-server-$(Get-Random)"
$secondaryservername = "secondary-server-$(Get-Random)"
# Set an admin login and password for your servers
$adminSqlLgin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
# The sample database name
$databaseName = "mySampleDatabase"
# The ip address ranges that you want to allow to access your servers
$primaryStartIp = "0.0.0.0"
$primaryEndIp = "0.0.0.0"
$secondaryStartIp = "0.0.0.0"
$secondaryEndIp = "0.0.0.0"
# The elastic pool names
$primaryPoolName = "PrimaryPool"
$secondarypoolname = "SecondaryPool"

# Set subscription 
Select-AzSubscription -Subscription $subscriptionId 

# Create two new resource groups
$primaryResourceGroupName = New-AzResourceGroup -Name $primaryResourceGroupName -Location $primaryLocation
$secondaryResourceGroupName = New-AzResourceGroup -Name $secondaryResourceGroupName -Location $secondaryLocation

# Create two new logical servers with a system wide unique server name

$primaryserver = New-AzSqlServer -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryservername `
    -Location $primaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLgin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$secondaryserver = New-AzSqlServer -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryservername `
    -Location $secondaryLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLgin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule for each server that allows access from the specified IP range
$primaryserverfirewallrule = New-AzSqlServerFirewallRule -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $primaryStartIp -EndIpAddress $primaryEndIp
$secondaryserverfirewallrule = New-AzSqlServerFirewallRule -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $secondaryStartIp -EndIpAddress $secondaryEndIp

# Create a pool in each of the servers
$primarypool = New-AzSqlElasticPool -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryservername `
    -ElasticPoolName $primaryPoolName `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50
$secondarypool = New-AzSqlElasticPool -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryservername `
    -ElasticPoolName $secondarypoolname `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50

# Create a blank database in the pool on the primary server
$database = New-AzSqlDatabase  -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryservername `
    -DatabaseName $databaseName `
    -ElasticPoolName $primaryPoolName

# Establish Active Geo-Replication
$database = Get-AzSqlDatabase -ResourceGroupName $primaryResourceGroupName `
    -ServerName $primaryservername `
    -DatabaseName $databaseName
$database | New-AzSqlDatabaseSecondary -PartnerResourceGroupName $secondaryResourceGroupName `
    -PartnerServerName $secondaryservername `
    -SecondaryElasticPoolName $secondarypoolname `
    -AllowConnections "All"

# Initiate a planned failover
$database = Get-AzSqlDatabase -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryservername `
    -DatabaseName $databaseName 
$database | Set-AzSqlDatabaseSecondary -PartnerResourceGroupName $primaryResourceGroupName -Failover

    
# Monitor Geo-Replication config and health after failover
$database = Get-AzSqlDatabase -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryservername `
    -DatabaseName $databaseName
$database | Get-AzSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryResourceGroupName `
    -PartnerServerName $primaryservername

# Clean up deployment 
# Remove-AzResourceGroup -ResourceGroupName $primaryResourceGroupName
# Remove-AzResourceGroup -ResourceGroupName $secondaryResourceGroupName