# Variables
$probename = "AppPortProbe6"
$rulename="AppPortLBRule6"
$RGname="mysftestclustergroup"
$port=8303

# Get the load balancer resource
$resource = Get-AzureRmResource | Where {$_.ResourceGroupName –eq $RGname -and $_.ResourceType -eq "Microsoft.Network/loadBalancers"} 
$slb = Get-AzureRmLoadBalancer -Name $resource.Name -ResourceGroupName $RGname

# Add a new probe configuration to the load balancer
$slb | Add-AzureRmLoadBalancerProbeConfig -Name $probename -Protocol Tcp -Port $port -IntervalInSeconds 15 -ProbeCount 2

# Add rule configuration to the load balancer
$probe = Get-AzureRmLoadBalancerProbeConfig -Name $probename -LoadBalancer $slb
$slb | Add-AzureRmLoadBalancerRuleConfig -Name $rulename -BackendAddressPool $slb.BackendAddressPools[0] -FrontendIpConfiguration $slb.FrontendIpConfigurations[0] -Probe $probe -Protocol Tcp -FrontendPort $port -BackendPort $port

# Set the goal state for the load balancer
$slb | Set-AzureRmLoadBalancer
