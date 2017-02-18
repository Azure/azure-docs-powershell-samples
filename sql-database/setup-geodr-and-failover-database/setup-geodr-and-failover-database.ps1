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


# Create a blank database with S0 performance level on the primary server
New-AzureRmSqlDatabase  -ResourceGroupName "PrimarySampleResourceGroup" `
    -ServerName "primary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" -RequestedServiceObjectiveName "S0"


# Establish Active Geo-Replication
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "MySampleDatabase" -ResourceGroupName "PrimarySampleResourceGroup" -ServerName "primary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"
$myDatabase | New-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName "SecondarySampleResourceGroup" -PartnerServerName "secondary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" -AllowConnections "All"


# Initiate a planned failover
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "MySampleDatabase" -ResourceGroupName "SecondarySampleResourceGroup" -ServerName "secondary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"
$myDatabase | Set-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName "PrimarySampleResourceGroup" -Failover

    
# Monitor Geo-Replication config and health after failover
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "MySampleDatabase" -ResourceGroupName "SecondarySampleResourceGroup" -ServerName "secondary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"
$myDatabase | Get-AzureRmSqlDatabaseReplicationLink -PartnerResourceGroupName "PrimarySampleResourceGroup" -PartnerServerName "primary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"


# Remove the replication link after the failover
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "MySampleDatabase" -ResourceGroupName "SecondarySampleResourceGroup" -ServerName "secondary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"
$secondaryLink = $myDatabase | Get-AzureRmSqlDatabaseReplicationLink -PartnerResourceGroupName "PrimarySampleResourceGroup" -PartnerServerName "primary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"
$secondaryLink | Remove-AzureRmSqlDatabaseSecondary


# Clean up
# Remove-AzureRmResourceGroup -ResourceGroupName "PrimarySampleResourceGroup"
# Remove-AzureRmResourceGroup -ResourceGroupName "SecondarySampleResourceGroup"