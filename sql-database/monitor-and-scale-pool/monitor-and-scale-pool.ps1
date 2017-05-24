# Login-AzureRmAccount
# Set the resource group name and location for your server
$resourcegroupname = "myResourceGroup-$(Get-Random)"
$location = "southcentralus"
# Set elastic poool names
$poolname = "MySamplePool"
# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server name has to be unique in the system
$servername = "server-$(Get-Random)"
# The sample database names
$firstdatabasename = "myFirstSampleDatabase"
$seconddatabasename = "mySecondSampleDatabase"
# The ip address range that you want to allow to access your server
$startip = "0.0.0.0"
$endip = "0.0.0.0"

# Create a new resource group
$resourcegroup = New-AzureRmResourceGroup -Name $resourcegroupname -Location $location

# Create a new server with a system wide unique server name
$server = New-AzureRmSqlServer -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create elastic database pool
$elasticpool = -AzureRmSqlElasticPool -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -ElasticPoolName $poolname `
    -Edition "Standard" `
    -Dtu 50 `
    -DatabaseDtuMin 10 `
    -DatabaseDtuMax 50

# Create a server firewall rule that allows access from the specified IP range
$serverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startip -EndIpAddress $endip

# Create two blank database in the pool
$firstdatabase = New-AzureRmSqlDatabase  -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -DatabaseName $firstdatabasename `
    -ElasticPoolName $poolname
$seconddatabase = New-AzureRmSqlDatabase  -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -DatabaseName $seconddatabasename `
    -ElasticPoolName $poolname

# Monitor the pool
$monitorparameters = @{
  ResourceId = "/subscriptions/$($(Get-AzureRMContext).Subscription.Id)/resourceGroups/$resourcegroupname/providers/Microsoft.Sql/servers/$servername/elasticPools/$poolname"
  TimeGrain = [TimeSpan]::Parse("00:05:00")
  MetricNames = "dtu_consumption_percent"
}
(Get-AzureRmMetric @monitorparameters -DetailedOutput).MetricValues

# Scale the pool
$elasticpool = Set-AzureRmSqlElasticPool -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -ElasticPoolName $poolname `
    -Edition "Standard" `
    -Dtu 100 `
    -DatabaseDtuMin 20 `
    -DatabaseDtuMax 100

# Add an alert that fires when the pool utilization reaches 90%
Add-AzureRMMetricAlertRule -ResourceGroup $resourcegroupname `
    -Name "mySampleAlertRule" `
    -Location $location `
    -TargetResourceId "/subscriptions/$($(Get-AzureRMContext).Subscription.Id)/resourceGroups/$resourcegroupname/providers/Microsoft.Sql/servers/$servername/elasticPools/$poolname" `
    -MetricName "dtu_consumption_percent" `
    -Operator "GreaterThan" `
    -Threshold 90 `
    -WindowSize $([TimeSpan]::Parse("00:05:00")) `
    -TimeAggregationOperator "Average" `
    -Actions $(New-AzureRmAlertRuleEmail -SendToServiceOwners)

# Clean up deployment 
# Remove-AzureRmResourceGroup -ResourceGroupName $resourcegroupname