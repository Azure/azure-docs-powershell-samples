# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server name has to be unique in the system
$servername = "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"
# The storage account name has to be unique in the system
$storageaccountname = $("sql$($(Get-AzureRMContext).Subscription.SubscriptionId)").substring(0,23).replace("-", "")
# Specify the email recipients for the threat detection alerts
$notificationemailreceipient = "changeto@your.email;changeto@your.email"

# Create a new resource group
New-AzureRmResourceGroup -Name "myResourceGroup" -Location "northcentralus"

# Create a new server with a system wide unique server name
New-AzureRmSqlServer -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a blank database with S0 performance level
New-AzureRmSqlDatabase  -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "MySampleDatabase" `
    -RequestedServiceObjectiveName "S0"

# Create a new Storage Account 
New-AzureRmStorageAccount -ResourceGroupName "myResourceGroup" `
    -AccountName $storageaccountname `
    -Location "northcentralus" `
    -Type "Standard_LRS"

# Set an auditing policy
Set-AzureRmSqlDatabaseAuditingPolicy -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "MySampleDatabase" `
    -StorageAccountName $storageaccountname `

# Set a threat detection policy
Set-AzureRmSqlDatabaseThreatDetectionPolicy -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "MySampleDatabase" `
    -StorageAccountName $storageaccountname `
    -NotificationRecipientsEmails $notificationemailreceipient `
    -EmailAdmins $False
