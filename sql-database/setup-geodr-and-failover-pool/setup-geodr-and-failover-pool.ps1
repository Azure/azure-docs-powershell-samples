# Sign in
# Login-AzureRmAccount


# Create two new resource groups
New-AzureRmResourceGroup -Name "PrimarySampleResourceGroup" -Location "northcentralus"
New-AzureRmResourceGroup -Name "SecondarySampleResourceGroup" -Location "southcentralus"


# Create two new logical servers with a system wide unique server-name
New-AzureRmSqlServer -ResourceGroupName "PrimarySampleResourceGroup" `
    -ServerName "primary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ServerAdmin", $(ConvertTo-SecureString -String "ASecureP@assw0rd" -AsPlainText -Force))
New-AzureRmSqlServer -ResourceGroupName "SecondarySampleResourceGroup" `
    -ServerName "secondary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -Location "southcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ServerAdmin", $(ConvertTo-SecureString -String "ASecureP@assw0rd" -AsPlainText -Force))


# Create a pool in each of the servers
New-AzureRmSqlElasticPool -ResourceGroupName "PrimarySampleResourceGroup" `
    -ServerName "primary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -ElasticPoolName "PrimaryPool" `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50
New-AzureRmSqlElasticPool -ResourceGroupName "SecondarySampleResourceGroup" `
    -ServerName "secondary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -ElasticPoolName "SecondaryPool" `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50


# Create a blank database in the pool on the primary server
New-AzureRmSqlDatabase  -ResourceGroupName "PrimarySampleResourceGroup" `
    -ServerName "primary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -ElasticPoolName "PrimaryPool"


# Establish Active Geo-Replication
$myDatabase = Get-AzureRmSqlDatabase -ResourceGroupName "PrimarySampleResourceGroup" `
    -ServerName "primary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase"
$myDatabase | New-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName "SecondarySampleResourceGroup" `
    -PartnerServerName "secondary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -SecondaryElasticPoolName "SecondaryPool" `
    -AllowConnections "All"


# Initiate a planned failover
$myDatabase = Get-AzureRmSqlDatabase -ResourceGroupName "SecondarySampleResourceGroup" `
    -ServerName "secondary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" 
$myDatabase | Set-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName "PrimarySampleResourceGroup" -Failover

    
# Monitor Geo-Replication config and health after failover
$myDatabase = Get-AzureRmSqlDatabase -ResourceGroupName "SecondarySampleResourceGroup" `
    -ServerName "secondary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase"
$myDatabase | Get-AzureRmSqlDatabaseReplicationLink -PartnerResourceGroupName "PrimarySampleResourceGroup" `
    -PartnerServerName "primary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"


# Clean up
# Remove-AzureRmResourceGroup -ResourceGroupName "PrimarySampleResourceGroup"
# Remove-AzureRmResourceGroup -ResourceGroupName "SecondarySampleResourceGroup"