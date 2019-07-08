# Set variables for your server and database
$ResourceGroupName = "myResourceGroup-$(Get-Random)"
$Location = "westus2"
$AdminLogin = "azureuser"
$Password = 'openssl rand -base64 16'
$ServerName = "mysqlserver-$(Get-Random)"
$DatabaseName = "mySampleDatabase"
$drLocation = "eastus2"
$drServerName = "mysqlsecondary-$(Get-Random)"
$FailoverGroupName = "failovergrouptutorial-$(Get-Random)"

# The ip address range that you want to allow to access your server 
# Leaving at 0.0.0.0 will prevent outside-of-azure connections
$startIp = "0.0.0.0"
$endIp = "0.0.0.0"

# Connect to Azure
Connect-AzAccount

# Set subscription ID
Set-AzContext -SubscriptionId $subscriptionId 

# Create a resource group
$resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location

# Create a server with a system wide unique server name
$server = New-AzSqlServer -ResourceGroupName $ResourceGroupName `
   -ServerName $ServerName `
   -Location $Location `
   -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential `
   -ArgumentList $AdminLogin, $(ConvertTo-SecureString ring $Password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroupName `
   -ServerName $ServerName `
   -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp

# Create General Purpose Gen4 database with 1 vCore
$database = New-AzSqlDatabase  -ResourceGroupName $ResourceGroupName `
   -ServerName $ServerName `
   -DatabaseName $DatabaseName `
   -Edition GeneralPurpose `
   -VCore 1 `
   -ComputeGeneration Gen4  `
   -MinimumCapacity 1 `
   -SampleName "AdventureWorksLT" `

# Create a secondary server in the failover region
New-AzSqlServer -ResourceGroupName $ResourceGroupName `
   -ServerName $drServerName `
   -Location $drLocation `
   -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential `
      -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $Password -AsPlainText -Force))

# Create a failover group between the servers
New-AzSqlDatabaseFailoverGroup `
   –ResourceGroupName $ResourceGroupName `
   -ServerName $ServerName `
   -PartnerServerName $drServerName  `
   –FailoverGroupName $FailoverGroupName `
   –FailoverPolicy Automatic `
   -GracePeriodWithDataLossHours 2

# Add the database to the failover group
Get-AzSqlDatabase `
   -ResourceGroupName $ResourceGroupName `
   -ServerName $ServerName `
   -DatabaseName $DatabaseName | `
Add-AzSqlDatabaseToFailoverGroup `
   -ResourceGroupName $ResourceGroupName `
   -ServerName $ServerName `
   -FailoverGroupName $FailoverGroupName

# Check role of secondary replica
(Get-AzSqlDatabaseFailoverGroup `
   -FailoverGroupName $FailoverGroupName `
   -ResourceGroupName $ResourceGroupName `
   -ServerName $drServerName).ReplicationRole

# Failover to secondary server
Switch-AzSqlDatabaseFailoverGroup `
   -ResourceGroupName $ResourceGroupName `
   -ServerName $drServerName `
   -FailoverGroupName $FailoverGroupName

# Revert failover to primary server
Switch-AzSqlDatabaseFailoverGroup `
   -ResourceGroupName $ResourceGroupName `
   -ServerName $ServerName `
   -FailoverGroupName $FailoverGroupName

# Clean up resources by removing the resource group
# Remove-AzResourceGroup -ResourceGroupName $ResourceGroupName

# Echo random password
echo $password
