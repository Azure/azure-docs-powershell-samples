# Login to Azure and set subscription context for the PowerShell session
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
    -DatabaseName "MySampleDatabase" -RequestedServiceObjectiveName "S0"


# Monitor the DTU consumption on the imported database in 5 minute intervals
$MonitorParameters = @{
  ResourceId = "/subscriptions/$($(Get-AzureRMContext).Subscription.SubscriptionId)/resourceGroups/SampleResourceGroup/providers/Microsoft.Sql/servers/server-$($(Get-AzureRMContext).Subscription.SubscriptionId)/databases/MySampleDatabase"
  TimeGrain = [TimeSpan]::Parse("00:05:00")
  MetricNames = "dtu_consumption_percent"
}
(Get-AzureRmMetric @MonitorParameters -DetailedOutput).MetricValues


# Scale the database performance to Standard S2
Set-AzureRmSqlDatabase -ResourceGroupName "SampleResourceGroup" `
    -ServerName "server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MySampleDatabase" `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S1"


# Set an alert rule to automatically monitor DTU in the future
Add-AzureRMMetricAlertRule -ResourceGroup "SampleResourceGroup" `
    -Name "MySampleAlertRule" `
    -Location "northcentralus" `
    -TargetResourceId "/subscriptions/$($(Get-AzureRMContext).Subscription.SubscriptionId)/resourceGroups/SampleResourceGroup/providers/Microsoft.Sql/servers/server-$($(Get-AzureRMContext).Subscription.SubscriptionId)/databases/MySampleDatabase" `
    -MetricName "dtu_consumption_percent" `
    -Operator "GreaterThan" `
    -Threshold 90 `
    -WindowSize $([TimeSpan]::Parse("00:05:00")) `
    -TimeAggregationOperator "Average" `
    -Actions $(New-AzureRmAlertRuleEmail -SendToServiceOwners)


# Clean up: Delete the resources group and ALL resources in the resource group
# Remove-AzureRmResourceGroup -ResourceGroupName "SampleResourceGroup"