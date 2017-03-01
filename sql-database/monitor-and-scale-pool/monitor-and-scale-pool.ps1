# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server name has to be unique in the system
$servername = "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)"

# Create a new resource group
New-AzureRmResourceGroup -Name "myResourceGroup" -Location "northcentralus"

# Create a new server with a system wide unique server-name
New-AzureRmSqlServer -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create two elastic database pools
New-AzureRmSqlElasticPool -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -ElasticPoolName "SamplePool" `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50

# Create two blank database in the pool
New-AzureRmSqlDatabase  -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "MyFirstSampleDatabase" `
    -ElasticPoolName "SamplePool"
New-AzureRmSqlDatabase  -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "MySecondSampleDatabase" `
    -ElasticPoolName "SamplePool"

# Monitor the pool
$MonitorParameters = @{
  ResourceId = "/subscriptions/$($(Get-AzureRMContext).Subscription.SubscriptionId)/resourceGroups/myResourceGroup/providers/Microsoft.Sql/servers/server-$($(Get-AzureRMContext).Subscription.SubscriptionId)/elasticPools/SamplePool"
  TimeGrain = [TimeSpan]::Parse("00:05:00")
  MetricNames = "dtu_consumption_percent"
}
(Get-AzureRmMetric @MonitorParameters -DetailedOutput).MetricValues

# Scale the pool
Set-AzureRmSqlElasticPool -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -ElasticPoolName "SamplePool" `
    -Edition "Standard" `
    -Dtu 100 `
    -DatabaseDtuMin 20 `
    -DatabaseDtuMax 100

# Add an alert that fires when the pool utilization reaches 90%
Add-AzureRMMetricAlertRule -ResourceGroup "myResourceGroup" `
    -Name "MySampleAlertRule" `
    -Location "northcentralus" `
    -TargetResourceId "/subscriptions/$($(Get-AzureRMContext).Subscription.SubscriptionId)/resourceGroups/myResourceGroup/providers/Microsoft.Sql/servers/server-$($(Get-AzureRMContext).Subscription.SubscriptionId)/elasticPools/SamplePool" `
    -MetricName "dtu_consumption_percent" `
    -Operator "GreaterThan" `
    -Threshold 90 `
    -WindowSize $([TimeSpan]::Parse("00:05:00")) `
    -TimeAggregationOperator "Average" `
    -Actions $(New-AzureRmAlertRuleEmail -SendToServiceOwners)
