# Sign in
# Login-AzureRmAccount

# Create new, or get existing resource group
New-AzureRmResourceGroup -Name "CopySampleResourceGroup" -Location "northcentralus"


# Create a new server with a system wide unique server-name
New-AzureRmSqlServer -ResourceGroupName "CopySampleResourceGroup" `
    -ServerName "source-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ServerAdmin", $(ConvertTo-SecureString -String "ASecureP@assw0rd" -AsPlainText -Force))
New-AzureRmSqlServer -ResourceGroupName "CopySampleResourceGroup" `
    -ServerName "target-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -Location "southcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ServerAdmin", $(ConvertTo-SecureString -String "ASecureP@assw0rd" -AsPlainText -Force))


# Create a blank database in the source-server
New-AzureRmSqlDatabase  -ResourceGroupName "CopySampleResourceGroup" `
    -ServerName "source-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" -RequestedServiceObjectiveName "S0"


# Copy source database to target server 
New-AzureRmSqlDatabaseCopy -ResourceGroupName "CopySampleResourceGroup" `
    -ServerName "source-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -CopyResourceGroupName "CopySampleResourceGroup" `
    -CopyServerName "target-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -CopyDatabaseName "CopyOfMySampleDatabase"

# Clean up
# Remove-AzureRmResourceGroup -ResourceGroupName "CopySampleResourceGroup"