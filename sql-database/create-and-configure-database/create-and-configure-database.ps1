# Sign in
# Login-AzureRmAccount


# Creat a new resource group
New-AzureRmResourceGroup -Name "SampleResourceGroup" -Location "northcentralus"


# Create a new server with a system wide unique server-name
New-AzureRmSqlServer -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ServerAdmin", $(ConvertTo-SecureString -String "ASecureP@assw0rd" -AsPlainText -Force))


# Create or update server firewall rule that allows access from a small IP range
New-AzureRmSqlServerFirewallRule -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -FirewallRuleName "AllowSome" -StartIpAddress "192.1.123.15" -EndIpAddress "192.1.123.19"


# Create a blank database with S0 performance level
New-AzureRmSqlDatabase  -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -RequestedServiceObjectiveName "S0"


# Cleanup: Delete the resource group and ALL resources in it
# Remove-AzureRmResourceGroup -ResourceGroupName "SampleResourceGroup"