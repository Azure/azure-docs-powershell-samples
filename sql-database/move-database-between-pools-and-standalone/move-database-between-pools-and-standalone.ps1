# Sign in
# Login-AzureRmAccount


# Creat a new resource group
New-AzureRmResourceGroup -Name "SampleResourceGroup" -Location "northcentralus"


# Create a new server with a system wide unique server-name
New-AzureRmSqlServer -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ServerAdmin", $(ConvertTo-SecureString -String "ASecureP@assw0rd" -AsPlainText -Force))


# Create two elastic database pools
New-AzureRmSqlElasticPool -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -ElasticPoolName "MyFirstPool" `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 20
New-AzureRmSqlElasticPool -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -ElasticPoolName "MySecondPool" `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50


# Create a blank database in the first pool
New-AzureRmSqlDatabase  -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -ElasticPoolName "MyFirstPool"


# Move the database to the second pool
Set-AzureRmSqlDatabase -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -ElasticPoolName "MySecondPool"


# Move the database into a standalone performance level
Set-AzureRmSqlDatabase -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -RequestedServiceObjectiveName "S0"

# Cleanup: Delete the resource group and ALL resources in it
# Remove-AzureRmResourceGroup -ResourceGroupName "SampleResourceGroup"