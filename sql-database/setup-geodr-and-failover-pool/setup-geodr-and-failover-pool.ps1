# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server names have to be unique in the system
$primaryservername = "primary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"
$sercondaryservername = "secondary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"

# Create two new resource groups
New-AzureRmResourceGroup -Name "myPrimaryResourceGroup" -Location "northcentralus"
New-AzureRmResourceGroup -Name "mySecondaryResourceGroup" -Location "southcentralus"

# Create two new logical servers with a system wide unique server-name
New-AzureRmSqlServer -ResourceGroupName "myPrimaryResourceGroup" `
    -ServerName $primaryservername `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
New-AzureRmSqlServer -ResourceGroupName "mySecondaryResourceGroup" `
    -ServerName $sercondaryservername `
    -Location "southcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a pool in each of the servers
New-AzureRmSqlElasticPool -ResourceGroupName "myPrimaryResourceGroup" `
    -ServerName $primaryservername `
    -ElasticPoolName "PrimaryPool" `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50
New-AzureRmSqlElasticPool -ResourceGroupName "mySecondaryResourceGroup" `
    -ServerName $sercondaryservername `
    -ElasticPoolName "SecondaryPool" `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50

# Create a blank database in the pool on the primary server
New-AzureRmSqlDatabase  -ResourceGroupName "myPrimaryResourceGroup" `
    -ServerName $primaryservername `
    -DatabaseName "MySampleDatabase" `
    -ElasticPoolName "PrimaryPool"

# Establish Active Geo-Replication
$myDatabase = Get-AzureRmSqlDatabase -ResourceGroupName "myPrimaryResourceGroup" `
    -ServerName $primaryservername `
    -DatabaseName "MySampleDatabase"
$myDatabase | New-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName "mySecondaryResourceGroup" `
    -PartnerServerName $sercondaryservername `
    -SecondaryElasticPoolName "SecondaryPool" `
    -AllowConnections "All"

# Initiate a planned failover
$myDatabase = Get-AzureRmSqlDatabase -ResourceGroupName "mySecondaryResourceGroup" `
    -ServerName $sercondaryservername `
    -DatabaseName "MySampleDatabase" 
$myDatabase | Set-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName "myPrimaryResourceGroup" -Failover

    
# Monitor Geo-Replication config and health after failover
$myDatabase = Get-AzureRmSqlDatabase -ResourceGroupName "mySecondaryResourceGroup" `
    -ServerName $sercondaryservername `
    -DatabaseName "MySampleDatabase"
$myDatabase | Get-AzureRmSqlDatabaseReplicationLink -PartnerResourceGroupName "myPrimaryResourceGroup" `
    -PartnerServerName $primaryservername
