# This script requires the following
# - Az.Resources
# - Az.Accounts
# - Az.Monitor
# - Az.Sql

# First, run Connect-AzAccount

# Set the subscription in which to create these objects. This is displayed on objects in the Azure portal.
$SubscriptionId = ''
# Set the resource group name and location for your server
$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "westus2"
# Set elastic pool name
$poolName = "MySamplePool"
# Set an admin login and password for your database
$adminSqlLogin = "SqlAdmin"
$password = (New-Guid).Guid # Generates a randomized GUID password. 
# Set server name - the logical server name has to be unique in the system
$serverName = "server-$(Get-Random)"
# The sample database names
$firstDatabaseName = "myFirstSampleDatabase"
$secondDatabaseName = "mySecondSampleDatabase"
# The ip address range that you want to allow to access your server via the firewall rule
$startIp = "0.0.0.0"
$endIp = "0.0.0.0"

# Set subscription 
Set-AzContext -SubscriptionId $subscriptionId 

# Create a new resource group
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a new server with a system wide unique server name
$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create elastic database pool
$elasticPool = New-AzSqlElasticPool -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -ElasticPoolName $poolName `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50

# Create a server firewall rule that allows access from the specified IP range
$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp

# Create two blank database in the pool
$firstDatabase = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $firstDatabaseName `
    -ElasticPoolName $poolName
$secondDatabase = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $secondDatabaseName `
    -ElasticPoolName $poolName

# Monitor the DTU consumption of the pool in 5 minute intervals
$monitorparameters = @{
  ResourceId = "/subscriptions/$($(Get-AzContext).Subscription.Id)/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/servers/$serverName/elasticPools/$poolName"
  TimeGrain = [TimeSpan]::Parse("00:05:00")
  MetricNames = "dtu_consumption_percent"
}
$metric = Get-AzMetric @monitorparameters
$metric.Data

# Scale the pool
$elasticPool = Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -ElasticPoolName $poolName `
    -Edition "Standard" `
    -Dtu 100 `
    -DatabaseDtuMin 20 `
    -DatabaseDtuMax 100

# Set up an Alert rule using Azure Monitor for the database
# Add an Alert that fires when the pool utilization reaches 90%
# Objects needed: an Action Group Receiver, an Action Group, Alert Criteria, and finally an Alert Rule.

# Creates an new action group receiver object with a target email address.
$receiver = New-AzActionGroupReceiver `
    -Name "my Sample Azure Admins" `
    -EmailAddress "azure-admins-group@contoso.com"

# Creates a new or updates an existing action group.
$actionGroup = Set-AzActionGroup `
    -Name "mysample-email-the-azure-admins" `
    -ShortName "AzAdminsGrp" `
    -ResourceGroupName $resourceGroupName `
    -Receiver $receiver

# Fetch the created AzActionGroup into an object of type Microsoft.Azure.Management.Monitor.Models.ActivityLogAlertActionGroup
$actionGroupObject = New-AzActionGroup -ActionGroupId $actionGroup.Id

# Create a criteria for the Alert to monitor.
$criteria = New-AzMetricAlertRuleV2Criteria `
    -MetricName "dtu_consumption_percent" `
    -TimeAggregation Average `
    -Operator GreaterThan `
    -Threshold 90

# Create the Alert rule.
# Add-AzMetricAlertRuleV2 adds or updates a V2 (non-classic) metric-based alert rule.
Add-AzMetricAlertRuleV2 -Name "mySample_Alert_DTU_consumption_pct" `
        -ResourceGroupName $resourceGroupName `
        -WindowSize (New-TimeSpan -Minutes 1) `
        -Frequency (New-TimeSpan -Minutes 1) `
        -TargetResourceId "/subscriptions/$($(Get-AzContext).Subscription.Id)/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/servers/$serverName/elasticPools/$poolName"  `
        -Condition $criteria `
        -ActionGroup $actionGroupObject `
        -Severity 3 #Informational

<#
# Set up an alert rule using Azure Monitor for the database
# Add a classic alert that fires when the pool utilization reaches 90%
# Note that Add-AzMetricAlertRule is deprecated. Use Add-AzMetricAlertRuleV2 instead.
Add-AzMetricAlertRule -ResourceGroup $resourceGroupName `
    -Name "mySampleAlertRule" `
    -Location $location `
    -TargetResourceId "/subscriptions/$($(Get-AzContext).Subscription.Id)/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/servers/$serverName/elasticPools/$poolName" `
    -MetricName "dtu_consumption_percent" `
    -Operator "GreaterThan" `
    -Threshold 90 `
    -WindowSize $([TimeSpan]::Parse("00:05:00")) `
    -TimeAggregationOperator "Average" `
    -Action $(New-AzAlertRuleEmail -SendToServiceOwner)
#>

# Clean up deployment 
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName