# Connect-AzAccount
# The SubscriptionId in which to create these objects
$SubscriptionId = ''
# Set the resource group name and location for your source server
$sourceResourceGroupName = "mySourceResourceGroup-$(Get-Random)"
$sourceResourceGroupLocation = "westus2"
# Set the resource group name and location for your target server
$targetResourceGroupname = "myTargetResourceGroup-$(Get-Random)"
$targetResourceGroupLocation = "eastus"
# Set an admin login and password for your server
$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server names have to be unique in the system
$sourceServerName = "source-server-$(Get-Random)"
$targetServerName = "target-server-$(Get-Random)"
# The sample database name
$sourceDatabaseName = "mySampleDatabase"
$targetDatabaseName = "CopyOfMySampleDatabase"
# The ip address range that you want to allow to access your servers
$sourceStartIp = "0.0.0.0"
$sourceEndIp = "0.0.0.0"
$targetStartIp = "0.0.0.0"
$targetEndIp = "0.0.0.0"

# Set subscription 
Set-AzContext -SubscriptionId $subscriptionId 

# Create two new resource groups
$sourceResourceGroup = New-AzResourceGroup -Name $sourceResourceGroupName -Location $sourceResourceGroupLocation
$targetResourceGroup = New-AzResourceGroup -Name $targetResourceGroupname -Location $targetResourceGroupLocation

# Create a server with a system wide unique server name
$sourceResourceGroup = New-AzSqlServer -ResourceGroupName $sourceResourceGroupName `
    -ServerName $sourceServerName `
    -Location $sourceResourceGroupLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$targetResourceGroup = New-AzSqlServer -ResourceGroupName $targetResourceGroupname `
    -ServerName $targetServerName `
    -Location $targetResourceGroupLocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
$sourceServerFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $sourceResourceGroupName `
    -ServerName $sourceServerName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $sourcestartip -EndIpAddress $sourceEndIp
$targetServerFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $targetResourceGroupname `
    -ServerName $targetServerName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $targetStartIp -EndIpAddress $targetEndIp

# Create a blank database in the source-server with an S0 performance level
$sourceDatabase = New-AzSqlDatabase  -ResourceGroupName $sourceResourceGroupName `
    -ServerName $sourceServerName `
    -DatabaseName $sourceDatabaseName -RequestedServiceObjectiveName "S0"

# Copy source database to the target server 
$databaseCopy = New-AzSqlDatabaseCopy -ResourceGroupName $sourceResourceGroupName `
    -ServerName $sourceServerName `
    -DatabaseName $sourceDatabaseName `
    -CopyResourceGroupName $targetResourceGroupname `
    -CopyServerName $targetServerName `
    -CopyDatabaseName $targetDatabaseName 

# Clean up deployment 
# Remove-AzResourceGroup -ResourceGroupName $sourceResourceGroupName
# Remove-AzResourceGroup -ResourceGroupName $targetResourceGroupname