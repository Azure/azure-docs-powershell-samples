# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server names have to be unique in the system
$primaryservername = "primary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"
$sercondaryservername = "secondary-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"

# Create two new resource groups
New-AzureRmResourceGroup -Name "myPrimaryResourceGroup" -Location "northcentralus"
New-AzureRmResourceGroup -Name "mySecondaryResourceGroup" -Location "southcentralus"

# Create two new logical servers with a system wide unique server name
New-AzureRmSqlServer -ResourceGroupName "myPrimaryResourceGroup" `
    -ServerName $primaryservername `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
New-AzureRmSqlServer -ResourceGroupName "mySecondaryResourceGroup" `
    -ServerName $sercondaryservername `
    -Location "southcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a blank database with S0 performance level on the primary server
New-AzureRmSqlDatabase  -ResourceGroupName "myPrimaryResourceGroup" `
    -ServerName $primaryservername `
    -DatabaseName "MySampleDatabase" -RequestedServiceObjectiveName "S0"

# Establish Active Geo-Replication
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "MySampleDatabase" -ResourceGroupName "myPrimaryResourceGroup" -ServerName $primaryservername
$myDatabase | New-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName "mySecondaryResourceGroup" -PartnerServerName $sercondaryservername -AllowConnections "All"

# Initiate a planned failover
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "MySampleDatabase" -ResourceGroupName "mySecondaryResourceGroup" -ServerName $sercondaryservername
$myDatabase | Set-AzureRmSqlDatabaseSecondary -PartnerResourceGroupName "myPrimaryResourceGroup" -Failover

# Monitor Geo-Replication config and health after failover
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "MySampleDatabase" -ResourceGroupName "mySecondaryResourceGroup" -ServerName $sercondaryservername
$myDatabase | Get-AzureRmSqlDatabaseReplicationLink -PartnerResourceGroupName "myPrimaryResourceGroup" -PartnerServerName $primaryservername

# Remove the replication link after the failover
$myDatabase = Get-AzureRmSqlDatabase -DatabaseName "MySampleDatabase" -ResourceGroupName "mySecondaryResourceGroup" -ServerName $sercondaryservername
$secondaryLink = $myDatabase | Get-AzureRmSqlDatabaseReplicationLink -PartnerResourceGroupName "myPrimaryResourceGroup" -PartnerServerName $primaryservername
$secondaryLink | Remove-AzureRmSqlDatabaseSecondary
