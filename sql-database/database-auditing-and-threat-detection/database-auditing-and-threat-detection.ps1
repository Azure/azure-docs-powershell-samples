# Sign in
# Login-AzureRmAccount


# Creat a new resource group
New-AzureRmResourceGroup -Name "SampleResourceGroup" -Location "northcentralus"


# Create a new server with a system wide unique server-name
New-AzureRmSqlServer -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ServerAdmin", $(ConvertTo-SecureString -String "ASecureP@assw0rd" -AsPlainText -Force))


# Create a blank database with S0 performance level
New-AzureRmSqlDatabase  -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -RequestedServiceObjectiveName "S0"


# Create a new Storage Account 
New-AzureRmStorageAccount -ResourceGroupName "SampleResourceGroup" `
    -AccountName $("sql$($(Get-AzureRMContext).Subscription.SubscriptionId)").substring(0,23).replace("-", "") `
    -Location "northcentralus" `
    -Type "Standard_LRS"


# Set an auditing policy
Set-AzureRmSqlDatabaseAuditingPolicy -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -StorageAccountName $("sql$($(Get-AzureRMContext).Subscription.SubscriptionId)").substring(0,23).replace("-", "") `


# Set a threat detection policy
Set-AzureRmSqlDatabaseThreatDetectionPolicy -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -StorageAccountName $("sql$($(Get-AzureRMContext).Subscription.SubscriptionId)").substring(0,23).replace("-", "") `
    -NotificationRecipientsEmails "admin@contoso.com;securityadmin@contoso.com" `
    -EmailAdmins $False


# Cleanup: Delete the resource group and ALL resources in it
# Remove-AzureRmResourceGroup -ResourceGroupName "SampleResourceGroup"
