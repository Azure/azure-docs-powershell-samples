# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server names have to be unique in the system
$sourceserver = "source-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"
$targetserver = "target-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"

# Create new, or get existing resource group
New-AzureRmResourceGroup -Name "myResourceGroup" -Location "northcentralus"


# Create a new server with a system wide unique server name
New-AzureRmSqlServer -ResourceGroupName "myResourceGroup" `
    -ServerName $sourceserver `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
New-AzureRmSqlServer -ResourceGroupName "myResourceGroup" `
    -ServerName "target-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -Location "southcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))


# Create a blank database in the source-server
New-AzureRmSqlDatabase  -ResourceGroupName "myResourceGroup" `
    -ServerName $sourceserver `
    -DatabaseName "MySampleDatabase" -RequestedServiceObjectiveName "S0"


# Copy source database to target server 
New-AzureRmSqlDatabaseCopy -ResourceGroupName "myResourceGroup" `
    -ServerName $sourceserver `
    -DatabaseName "MySampleDatabase" `
    -CopyResourceGroupName "myResourceGroup" `
    -CopyServerName $targetserver `
    -CopyDatabaseName "CopyOfMySampleDatabase"
