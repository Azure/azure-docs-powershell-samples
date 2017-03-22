# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server names have to be unique in the system
$sourceserver = "source-server-$(Get-Random)"
$targetserver = "target-server-$(Get-Random)"
# The ip address range that you want to allow to access your DB
$startip = "0.0.0.0"
$endip = "255.255.255.255"

# Create a resource group
New-AzureRmResourceGroup -Name "myResourceGroup" -Location "westeurope"


# Create a server with a system wide unique server name
New-AzureRmSqlServer -ResourceGroupName "myResourceGroup" `
    -ServerName $sourceserver `
    -Location "westeurope" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
New-AzureRmSqlServer -ResourceGroupName "myResourceGroup" `
    -ServerName $targetserver `
    -Location "southcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
New-AzureRmSqlServerFirewallRule -ResourceGroupName "myResourceGroup" `
    -ServerName $sourceserver `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startip -EndIpAddress $endip
New-AzureRmSqlServerFirewallRule -ResourceGroupName "myResourceGroup" `
    -ServerName $targetserver `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startip -EndIpAddress $endip

# Create a blank database in the source-server with an S0 performance level
New-AzureRmSqlDatabase  -ResourceGroupName "myResourceGroup" `
    -ServerName $sourceserver `
    -DatabaseName "mySampleDatabase" -RequestedServiceObjectiveName "S0"

# Copy source database to the target server 
New-AzureRmSqlDatabaseCopy -ResourceGroupName "myResourceGroup" `
    -ServerName $sourceserver `
    -DatabaseName "mySampleDatabase" `
    -CopyResourceGroupName "myResourceGroup" `
    -CopyServerName $targetserver `
    -CopyDatabaseName "CopyOfMySampleDatabase"
