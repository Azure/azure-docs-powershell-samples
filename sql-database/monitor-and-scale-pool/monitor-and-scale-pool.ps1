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
    -ElasticPoolName "SamplePool" `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50


# Create a blank database in the first pool
New-AzureRmSqlDatabase  -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -ElasticPoolName "SamplePool"


# Monitor the pool
$MonitorParameters = @{
  ResourceId = "/subscriptions/$($(Get-AzureRMContext).Subscription.SubscriptionId)/resourceGroups/SampleResourceGroup/providers/Microsoft.Sql/servers/server-$($(Get-AzureRMContext).Subscription.SubscriptionId)/elasticPools/SamplePool"
  TimeGrain = [TimeSpan]::Parse("00:05:00")
  MetricNames = "dtu_consumption_percent"
}
(Get-AzureRmMetric @MonitorParameters -DetailedOutput).MetricValues


# Scale the pool
Set-AzureRmSqlElasticPool -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -ElasticPoolName "SamplePool" `
    -Edition "Standard" `
    -Dtu 100 `
    -DatabaseDtuMin 20 `
    -DatabaseDtuMax 100


# Add an alert that fires when the pool utilization reaches 90%
Add-AzureRMMetricAlertRule -ResourceGroup "SampleResourceGroup" `
    -Name "MySampleAlertRule" `
    -Location "northcentralus" `
    -TargetResourceId "/subscriptions/$($(Get-AzureRMContext).Subscription.SubscriptionId)/resourceGroups/SampleResourceGroup/providers/Microsoft.Sql/servers/server-$($(Get-AzureRMContext).Subscription.SubscriptionId)/elasticPools/SamplePool" `
    -MetricName "dtu_consumption_percent" `
    -Operator "GreaterThan" `
    -Threshold 90 `
    -WindowSize $([TimeSpan]::Parse("00:05:00")) `
    -TimeAggregationOperator "Average" `
    -Actions $(New-AzureRmAlertRuleEmail -SendToServiceOwners)


# Cleanup: Delete the resource group and ALL resources in it
# Remove-AzureRmResourceGroup -ResourceGroupName "SampleResourceGroup"