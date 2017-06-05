# Login-AzureRmAccount
# Set the resource group name and location for your server
$resourcegroupname = "myResourceGroup-$(Get-Random)"
$location = "southcentralus"
# Set an admin login and password for your server
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server name has to be unique in the system
$servername = "server-$(Get-Random)"
# The sample database name
$databasename = "mySampleDatabase"
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

# Create a server firewall rule that allows access from the specified IP range
$serverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startip -EndIpAddress $endip

# Create a blank database with S0 performance level
$database = New-AzureRmSqlDatabase  -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -DatabaseName $databasename -RequestedServiceObjectiveName "S0"

# Monitor the DTU consumption on the imported database in 5 minute intervals
$MonitorParameters = @{
  ResourceId = "/subscriptions/$($(Get-AzureRMContext).Subscription.Id)/resourceGroups/$resourcegroupname/providers/Microsoft.Sql/servers/$servername/databases/$databasename"
  TimeGrain = [TimeSpan]::Parse("00:05:00")
  MetricNames = "dtu_consumption_percent"
  
}
(Get-AzureRmMetric @MonitorParameters -DetailedOutput).MetricValues

# Scale the database performance to Standard S1
$database = Set-AzureRmSqlDatabase -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -DatabaseName $databasename `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S1"

# Set an alert rule to automatically monitor DTU in the future
Add-AzureRMMetricAlertRule -ResourceGroup $resourcegroupname `
    -Name "MySampleAlertRule" `
    -Location $location `
    -TargetResourceId "/subscriptions/$($(Get-AzureRMContext).Subscription.Id)/resourceGroups/$resourcegroupname/providers/Microsoft.Sql/servers/$servername/databases/$databasename" `
    -MetricName "dtu_consumption_percent" `
    -Operator "GreaterThan" `
    -Threshold 90 `
    -WindowSize $([TimeSpan]::Parse("00:05:00")) `
    -TimeAggregationOperator "Average" `
    -Actions $(New-AzureRmAlertRuleEmail -SendToServiceOwners)

# Clean up deployment 
# Remove-AzureRmResourceGroup -ResourceGroupName $resourcegroupname