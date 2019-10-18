
# Set variables for your server and database
$subscriptionId = '<Subscription-ID>'
$randomIdentifier = $(Get-Random)
$resourceGroupName = "myResourceGroup-$randomIdentifier"
$location = "East US"
$adminLogin = "azureuser"
$password = "PWD27!"+(New-Guid).Guid
$serverName = "mysqlserver-$randomIdentifier"
$poolName = "myElasticPool"
$databaseName = "mySampleDatabase"
$drLocation = "West US"
$drServerName = "mysqlsecondary-$randomIdentifier"
$failoverGroupName = "failovergrouptutorial-$randomIdentifier"


# The ip address range that you want to allow to access your server 
# Leaving at 0.0.0.0 will prevent outside-of-azure connections
$startIp = "0.0.0.0"
$endIp = "0.0.0.0"

# Show randomized variables
Write-host "Resource group name is" $resourceGroupName 
Write-host "Password is" $password  
Write-host "Server name is" $serverName 
Write-host "DR Server name is" $drServerName 
Write-host "Failover group name is" $failoverGroupName


# Set subscription ID
Set-AzContext -SubscriptionId $subscriptionId 

# Create a resource group
Write-host "Creating resource group..."
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag @{Owner="SQLDB-Samples"}
$resourceGroup

# Create a server with a system-wide unique server name
Write-host "Creating primary logical server..."
New-AzSqlServer -ResourceGroupName $resourceGroupName `
   -ServerName $serverName `
   -Location $location `
   -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential `
   -ArgumentList $adminLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
Write-host "Primary logical server = " $serverName

# Create a server firewall rule that allows access from the specified IP range
Write-host "Configuring firewall for primary logical server..."
New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
   -ServerName $serverName `
   -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
Write-host "Firewall configured" 

# Create General Purpose Gen5 database with 2 vCore
Write-host "Creating a gen5 2 vCore database..."
$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
   -ServerName $serverName `
   -DatabaseName $databaseName `
   -Edition "GeneralPurpose" `
   -VCore 2 `
   -ComputeGeneration Gen5 `
   -MinimumCapacity 1 `
   -SampleName "AdventureWorksLT"
$database

# Create primary Gen5 elastic 2 vCore pool
Write-host "Creating elastic pool..."
$elasticPool = New-AzSqlElasticPool -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -ElasticPoolName $poolName `
    -Edition "GeneralPurpose" `
    -vCore 2 `
    -ComputeGeneration Gen5
$elasticPool

# Add single db into elastic pool
Write-host "Creating elastic pool..."
$addDatabase = Set-AzSqlDatabase -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -ElasticPoolName $poolName
$addDatabase

# Create a secondary server in the failover region
Write-host "Creating a secondary logical server in the failover region..."
New-AzSqlServer -ResourceGroupName $resourceGroupName `
   -ServerName $drServerName `
   -Location $drLocation `
   -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential `
      -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
Write-host "Secondary logical server =" $drServerName

# Create a server firewall rule that allows access from the specified IP range
Write-host "Configuring firewall for secondary logical server..."
New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
   -ServerName $drServerName `
   -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
Write-host "Firewall configured" 

# Create secondary Gen5 elastic 2 vCore pool
Write-host "Creating secondary elastic pool..."
$elasticPool = New-AzSqlElasticPool -ResourceGroupName $resourceGroupName `
    -ServerName $drServerName `
    -ElasticPoolName $poolName `
    -Edition "GeneralPurpose" `
    -vCore 2 `
    -ComputeGeneration Gen5
$elasticPool


# Create a failover group between the servers
Write-host "Creating failover group..." 
New-AzSqlDatabaseFailoverGroup `
  –ResourceGroupName $resourceGroupName `
   -ServerName $serverName `
   -PartnerServerName $drServerName  `
   –FailoverGroupName $failoverGroupName `
   –FailoverPolicy Automatic `
   -GracePeriodWithDataLossHours 2
Write-host "Failover group created successfully." 

# Add elastic pool to the failover group
Write-host "Enumerating databases in elastic pool...." 
$FailoverGroup = Get-AzSqlDatabaseFailoverGroup `
                 -ResourceGroupName $resourceGroupName `
                 -ServerName $serverName `
                 -FailoverGroupName $failoverGroupName
$databases = Get-AzSqlElasticPoolDatabase `
               -ResourceGroupName $resourceGroupName `
               -ServerName $serverName `
               -ElasticPoolName $poolName
Write-host "Adding databases to failover group..." 
$failoverGroup = $failoverGroup | Add-AzSqlDatabaseToFailoverGroup `
                                  -Database $databases 
$failoverGroup

# Check role of secondary replica
Write-host "Confirming the secondary server is secondary...." 
(Get-AzSqlDatabaseFailoverGroup `
   -FailoverGroupName $failoverGroupName `
   -ResourceGroupName $resourceGroupName `
   -ServerName $drServerName).ReplicationRole

# Failover to secondary server
Write-host "Failing over failover group to the secondary..." 
Switch-AzSqlDatabaseFailoverGroup `
   -ResourceGroupName $resourceGroupName `
   -ServerName $drServerName `
   -FailoverGroupName $failoverGroupName
Write-host "Failover group failed over to" $drServerName 

# Check role of secondary replica
Write-host "Confirming the secondary server is now primary" 
(Get-AzSqlDatabaseFailoverGroup `
   -FailoverGroupName $failoverGroupName `
   -ResourceGroupName $resourceGroupName `
   -ServerName $drServerName).ReplicationRole

# Revert failover to primary server
Write-host "Failing over failover group to the primary...." 
Switch-AzSqlDatabaseFailoverGroup `
   -ResourceGroupName $resourceGroupName `
   -ServerName $serverName `
   -FailoverGroupName $failoverGroupName
Write-host "Failover group failed over to" $serverName 

# Clean up resources by removing the resource group
# Write-host "Removing resource group..."
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName
# Write-host "Resource group removed =" $resourceGroupName
