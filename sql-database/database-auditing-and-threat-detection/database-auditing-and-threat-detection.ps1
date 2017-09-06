# Login-AzureRmAccount
# Set the resource group name and location for your server
$resourcegroupname = "myResourceGroup-$(Get-Random)"
$location = "southcentralus"
# Set an admin login and password for your server
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server name has to be unique in the system
$servername = "server-$(Get-Random)"
# The sample database name
$databasename = "mySampleDatabase"
# The ip address range that you want to allow to access your server
$startip = "0.0.0.0"
$endip = "0.0.0.0"
# The storage account name has to be unique in the system
$storageaccountname = $("sql$($(Get-AzureRMContext).Subscription.Id)").substring(0,23).replace("-", "")
# Specify the email recipients for the threat detection alerts
$notificationemailreceipient = "changeto@your.email;changeto@your.email"

# Create a new resource group
$resourcegroup = New-AzureRmResourceGroup -Name $resourcegroupname -Location $location

# Create a new server with a system wide unique server name
$server = New-AzureRmSqlServer -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
$serverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startip -EndIpAddress $endip

# Create a blank database with S0 performance level
$database = New-AzureRmSqlDatabase  -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -DatabaseName $databasename -RequestedServiceObjectiveName "S0"
    
# Create a Storage Account 
$storageaccount = New-AzureRmStorageAccount -ResourceGroupName $resourcegroupname `
    -AccountName $storageaccountname `
    -Location $location `
    -Type "Standard_LRS"

# Set an auditing policy
$auditpolicy = Set-AzureRmSqlDatabaseAuditingPolicy -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -DatabaseName $databasename `
    -StorageAccountName $storageaccountname 

# Set a threat detection policy
#threatdetectionpolicy = Set-AzureRmSqlDatabaseThreatDetectionPolicy -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -DatabaseName $databasename`
    -StorageAccountName $storageaccountname `
    -NotificationRecipientsEmails $notificationemailreceipient `
    -EmailAdmins $False

# Clean up deployment 
# Remove-AzureRmResourceGroup -ResourceGroupName $resourcegroupname
