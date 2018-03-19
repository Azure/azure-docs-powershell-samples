Login-AzureRmAccount
Get-AzureRmSubscription
Set-AzureRmContext -SubscriptionId 'yourSubscriptionId'

$groupname = "mysfclustergroup"
$start=3400
$end=4400

# Get the load balancer resource
$resource = Get-AzureRmResource | Where {$_.ResourceGroupName –eq $groupname -and $_.ResourceType -eq "Microsoft.Network/loadBalancers"} 
$lb = Get-AzureRmResource -ResourceGroupName $groupname -ResourceType Microsoft.Network/loadBalancers -ResourceName $resource.Name

# Update the front end port range
$lb.Properties.inboundNatPools.properties.frontendPortRangeStart = $start
$lb.Properties.inboundNatPools.properties.frontendPortRangeEnd = $end

# Write the inbound NAT pools properties
Write-Host ($lb.Properties.inboundNatPools | Format-List | Out-String)

# Update the load balancer
Set-AzureRmResource -PropertyObject $lb.Properties -ResourceGroupName $groupname -ResourceType Microsoft.Network/loadBalancers -ResourceName $lb.name  -Force

