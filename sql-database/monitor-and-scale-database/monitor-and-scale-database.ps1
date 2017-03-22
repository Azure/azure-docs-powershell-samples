# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server name has to be unique in the system
$servername = "server-$(Get-Random)"
$startip = "0.0.0.0"
$endip = "255.255.255.255"

# Create a new resource group
New-AzureRmResourceGroup -Name "myResourceGroup" -Location "westeurope"

# Create a new server with a system wide unique server name
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
    -DatabaseName "mySampleDatabase" -RequestedServiceObjectiveName "S0"

# Monitor the DTU consumption on the imported database in 5 minute intervals
$MonitorParameters = @{
  ResourceId = "/subscriptions/$($(Get-AzureRMContext).Subscription.SubscriptionId)/resourceGroups/myResourceGroup/providers/Microsoft.Sql/servers/$servername/databases/mySampleDatabase"
  TimeGrain = [TimeSpan]::Parse("00:05:00")
  MetricNames = "dtu_consumption_percent"
}
(Get-AzureRmMetric @MonitorParameters -DetailedOutput).MetricValues

# Scale the database performance to Standard S1
Set-AzureRmSqlDatabase -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "mySampleDatabase" `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S1"

# Set an alert rule to automatically monitor DTU in the future
Add-AzureRMMetricAlertRule -ResourceGroup "myResourceGroup" `
    -Name "MySampleAlertRule" `
    -Location "westeurope" `
    -TargetResourceId "/subscriptions/$($(Get-AzureRMContext).Subscription.SubscriptionId)/resourceGroups/myResourceGroup/providers/Microsoft.Sql/servers/$servername/databases/mySampleDatabase" `
    -MetricName "dtu_consumption_percent" `
    -Operator "GreaterThan" `
    -Threshold 90 `
    -WindowSize $([TimeSpan]::Parse("00:05:00")) `
    -TimeAggregationOperator "Average" `
    -Actions $(New-AzureRmAlertRuleEmail -SendToServiceOwners)

