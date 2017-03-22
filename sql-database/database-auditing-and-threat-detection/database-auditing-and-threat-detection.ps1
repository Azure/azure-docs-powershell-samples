# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server name has to be unique in the system
$servername = "server-$(Get-Random)"
# The storage account name has to be unique in the system
$storageaccountname = "sqlauditing$(Get-Random)"
# Specify the email recipients for the threat detection alerts
$notificationemailreceipient = "changeto@your.email;changeto@your.email"
# The ip address range that you want to allow to access your DB
$startip = "0.0.0.0"
$endip = "255.255.255.255"

# Create a resource group
New-AzureRmResourceGroup -Name "myResourceGroup" -Location "westeurope"

# Create a server with a system wide unique server name
New-AzureRmSqlServer -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -Location "westeurope" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
New-AzureRmSqlServerFirewallRule -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startip -EndIpAddress $endip

# Create a blank database with S0 performance level
New-AzureRmSqlDatabase  -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "mySampleDatabase" `
    -RequestedServiceObjectiveName "S0"
    
# Create a Storage Account 
New-AzureRmStorageAccount -ResourceGroupName "myResourceGroup" `
    -AccountName $storageaccountname `
    -Location "westeurope" `
    -Type "Standard_LRS"

# Set an auditing policy
Set-AzureRmSqlDatabaseAuditingPolicy -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "mySampleDatabase" `
    -StorageAccountName $storageaccountname `

# Set a threat detection policy
Set-AzureRmSqlDatabaseThreatDetectionPolicy -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "mySampleDatabase" `
    -StorageAccountName $storageaccountname `
    -NotificationRecipientsEmails $notificationemailreceipient `
    -EmailAdmins $False
