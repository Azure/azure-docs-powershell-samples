# Login-AzureRmAccount
# Set the resource group name and location for your serverw
$primaryresourcegroupname = "myPrimaryResourceGroup-$(Get-Random)"
$secondaryresourcegroupname = "mySecondaryResourceGroup-$(Get-Random)"
$primarylocation = "westus2"
$secondarylocation = "southcentralus"
# The logical server names have to be unique in the system
$primaryservername = "primary-server-$(Get-Random)"
$secondaryservername = "secondary-server-$(Get-Random)"
# Set an admin login and password for your servers
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The sample database name
$databasename = "mySampleDatabase"
# The ip address ranges that you want to allow to access your servers
$primarystartip = "0.0.0.0"
$primaryendip = "0.0.0.0"
$secondarystartip = "0.0.0.0"
$secondaryendip = "0.0.0.0"
# The elastic pool names
$primarypoolname = "PrimaryPool"
$secondarypoolname = "SecondaryPool"

# Create two new resource groups
$primaryresourcegroupname = New-AzureRmResourceGroup -Name $primaryresourcegroupname -Location $primarylocation
$secondaryresourcegroupname = New-AzureRmResourceGroup -Name $secondaryresourcegroupname -Location $secondarylocation

# Create two new logical servers with a system wide unique server name

$primaryserver = New-AzureRmSqlServer -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -Location $primarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$secondaryserver = New-AzureRmSqlServer -ResourceGroupName $secondaryresourcegroupname `
    -ServerName $secondaryservername `
    -Location $secondarylocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule for each server that allows access from the specified IP range
$primaryserverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $primarystartip -EndIpAddress $primaryendip
$secondaryserverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $secondaryresourcegroupname `
    -ServerName $secondaryservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $secondarystartip -EndIpAddress $secondaryendip

# Create a pool in each of the servers
$primarypool = New-AzureRmSqlElasticPool -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -ElasticPoolName $primarypoolname `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50
$secondarypool = New-AzureRmSqlElasticPool -ResourceGroupName $secondaryresourcegroupname `
    -ServerName $secondaryservername `
    -ElasticPoolName $secondarypoolname `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50

# Create a blank database in the pool on the primary server
$database = New-AzureRmSqlDatabase  -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -DatabaseName $databasename `
    -ElasticPoolName $primarypoolname

# Establish Active Geo-Replication
$database = Get-AzureRmSqlDatabase -ResourceGroupName $primaryresourcegroupname `
    -ServerName $primaryservername `
    -DatabaseName $databasename
$database | New-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName $secondaryresourcegroupname `
    -PartnerServerName $secondaryservername `
    -SecondaryElasticPoolName $secondarypoolname `
    -AllowConnections "All"

# Initiate a planned failover
$database = Get-AzureRmSqlDatabase -ResourceGroupName $secondaryresourcegroupname `
    -ServerName $secondaryservername `
    -DatabaseName $databasename 
$database | Set-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName $primaryresourcegroupname -Failover

    
# Monitor Geo-Replication config and health after failover
$database = Get-AzureRmSqlDatabase -ResourceGroupName $secondaryresourcegroupname `
    -ServerName $secondaryservername `
    -DatabaseName $databasename
$database | Get-AzureRmSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryresourcegroupname `
    -PartnerServerName $primaryservername

# Clean up deployment 
# Remove-AzureRmResourceGroup -ResourceGroupName $primaryresourcegroupname
# Remove-AzureRmResourceGroup -ResourceGroupName $secondaryresourcegroupname
