# Variables for common values
$rgName='MyResourceGroup'
$location='eastus'

# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a resource group.
New-AzResourceGroup -Name $rgName -Location $location

# Create an availability set for the two VMs that host both websites.
$as = New-AzAvailabilitySet -ResourceGroupName $rgName -Location $location `
  -Name MyAvailabilitySet -Sku Aligned -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2

# Create a virtual network and a subnet.
$subnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet' -AddressPrefix 10.0.0.0/24

$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name MyVnet `
  -AddressPrefix 10.0.0.0/16 -Location $location -Subnet $subnet

# Create three public IP addresses; one for the load balancer and two for the front-end IP configurations.
$publicIpLB = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-LoadBalancer' `
  -Location $location -AllocationMethod Dynamic

$publicIpContoso = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-Contoso' `
  -Location $location -AllocationMethod Dynamic

$publicIpFabrikam = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-Fabrikam' `
  -Location $location -AllocationMethod Dynamic

# Create two front-end IP configurations for both web sites.
$feipcontoso = New-AzLoadBalancerFrontendIpConfig -Name 'FeContoso' -PublicIpAddress $publicIpContoso
$feipfabrikam = New-AzLoadBalancerFrontendIpConfig -Name 'FeFabrikam' -PublicIpAddress $publicIpFabrikam

# Create the back-end address pools.
$bepoolContoso = New-AzLoadBalancerBackendAddressPoolConfig -Name 'BeContoso'
$bepoolFabrikam = New-AzLoadBalancerBackendAddressPoolConfig -Name 'BeFabrikam'

# Create a probe on port 80.
$probe = New-AzLoadBalancerProbeConfig -Name 'MyProbe' -Protocol Http -Port 80 `
  -RequestPath / -IntervalInSeconds 360 -ProbeCount 5

# Create the load balancing rules.
$contosorule = New-AzLoadBalancerRuleConfig -Name 'LBRuleContoso' -Protocol Tcp `
  -Probe $probe -FrontendPort 5000 -BackendPort 5000 `
  -FrontendIpConfiguration $feipContoso -BackendAddressPool $bePoolContoso

$fabrikamrule = New-AzLoadBalancerRuleConfig -Name 'LBRuleFabrikam' -Protocol Tcp `
  -Probe $probe -FrontendPort 5000 -BackendPort 5000 `
  -FrontendIpConfiguration $feipFabrikam -BackendAddressPool $bePoolfabrikam

# Create a load balancer.
$lb = New-AzLoadBalancer -ResourceGroupName $rgName -Name 'MyLoadBalancer' -Location $location `
  -FrontendIpConfiguration $feipcontoso,$feipfabrikam -BackendAddressPool $bepoolContoso,$bepoolfabrikam `
  -Probe $probe -LoadBalancingRule $contosorule,$fabrikamrule

# ############## VM1 ###############

# Create an Public IP for the first VM.
$publicipvm1 = New-AzPublicIpAddress -ResourceGroupName $rgName -Name MyPublicIp-Vm1 `
  -location $location -AllocationMethod Dynamic

# Create IP configurations for Contoso and Fabrikam.
$ipconfig1 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig1' `
  -Subnet $vnet.subnets[0] -Primary  

$ipconfig2 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig2' `
  -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $bepoolContoso
 
$ipconfig3 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig3' `
  -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $bepoolfabrikam 

# Create a network interface for VM1.
$nicVM1 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
-Name 'MyNic-VM1' -IpConfiguration $ipconfig1, $ipconfig2, $ipconfig3

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig -VMName 'myVM1' -VMSize Standard_DS2 -AvailabilitySetId $as.Id | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'myVM1' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
  -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nicVM1.Id

# Create a virtual machine
$vm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

############### VM2 ###############

# Create an Public IP for the second VM.

$publicipvm1 = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-Vm2' `
  -location $location -AllocationMethod Dynamic

# Create IP configurations for Contoso and Fabrikam.
$ipconfig1 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig1' `
  -Subnet $vnet.subnets[0] -Primary  

$ipconfig2 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig2' `
  -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $bepoolContoso 

$ipconfig3 = New-AzNetworkInterfaceIpConfig -Name 'ipconfig3' `
  -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $bepoolfabrikam 

# Create a network interface for VM2.
$nicVM2 = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
-Name 'MyNic-VM2' -IpConfiguration $ipconfig1, $ipconfig2, $ipconfig3

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig -VMName 'myVM2' -VMSize Standard_DS2 -AvailabilitySetId $as.Id | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'myVM2' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
  -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nicVM2.Id

# Create a virtual machine
$vm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

