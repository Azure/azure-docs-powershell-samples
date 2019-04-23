# Dual-Stack VNET with 2 VMs.ps1
#	Deploys Dual-stack (IPv4+IPv6) VNET with 2 VM's and BASIC Load Balancer with IPv4 and IPv6 Public IP's

# Register for IPv6 for Azure virtual network
# It takes up to 30 minutes for feature registration to complete. 
Register-AzProviderFeature -FeatureName AllowIPv6VirtualNetwork -ProviderNamespace Microsoft.Network
Get-AzProviderFeature -FeatureName AllowIPv6VirtualNetwork -ProviderNamespace Microsoft.Network
Register-AzResourceProvider -ProviderNamespace Microsoft.Network
#Create Resource Group to contain the deployment
$rg = New-AzResourceGroup -ResourceGroupName "dsRG1" -Location "east us"

#Create the Public IP's needed for the deployment
$PublicIP_v4 = New-AzPublicIpAddress -Name "dsPublicIP_v4" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic -IpAddressVersion IPv4
$PublicIP_v6 = New-AzPublicIpAddress -Name "dsPublicIP_v6" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic -IpAddressVersion IPv6

$RdpPublicIP_1 = New-AzPublicIpAddress -Name "RdpPublicIP_1" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic -IpAddressVersion IPv4
$RdpPublicIP_2 = New-AzPublicIpAddress -Name "RdpPublicIP_2" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic -IpAddressVersion IPv4


#Create Basic load balancer
$frontendIPv4 = New-AzLoadBalancerFrontendIpConfig -Name "dsLbFrontEnd_v4" -PublicIpAddress $PublicIP_v4
$frontendIPv6 = New-AzLoadBalancerFrontendIpConfig -Name "dsLbFrontEnd_v6" -PublicIpAddress $PublicIP_v6

$backendPoolv4 = New-AzLoadBalancerBackendAddressPoolConfig -Name "dsLbBackEndPool_v4"
$backendPoolv6 = New-AzLoadBalancerBackendAddressPoolConfig -Name "dsLbBackEndPool_v6"

$lbrule_v4 = New-AzLoadBalancerRuleConfig -Name "dsLBrule_v4" -FrontendIpConfiguration $frontendIPv4 -BackendAddressPool $backendPoolv4 -Protocol Tcp -FrontendPort 80 -BackendPort 80
$lbrule_v6 = New-AzLoadBalancerRuleConfig -Name "dsLBrule_v6" -FrontendIpConfiguration $frontendIPv6 -BackendAddressPool $backendPoolv6 -Protocol Tcp -FrontendPort 80 -BackendPort 80

$lb = New-AzLoadBalancer -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Name "MyLoadBalancer" -Sku "Basic" -FrontendIpConfiguration $frontendIPv4,$frontendIPv6 -BackendAddressPool $backendPoolv4,$backendPoolv6 -LoadBalancingRule $lbrule_v4,$lbrule_v6

#Create Availability Set
$avset = New-AzAvailabilitySet -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Name "dsAVset" -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2 -Sku aligned

#Create Network Security Group and Rules
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'myNetworkSecurityGroupRuleRDP' -Description 'Allow RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
$rule2 = New-AzNetworkSecurityRuleConfig -Name 'myNetworkSecurityGroupRuleHTTP' -Description 'Allow HTTP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 -SourceAddressPrefix * -SourcePortRange 80 -DestinationAddressPrefix * -DestinationPortRange 80

$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Name "dsNSG1" -SecurityRules $rule1,$rule2

#Create Virtual Network and Subnet
# Create dual stack subnet config
$subnet = New-AzVirtualNetworkSubnetConfig -Name "dsSubnet" -AddressPrefix "10.0.0.0/24","ace:cab:deca:deed::/64"

# Create the virtual network
$vnet = New-AzVirtualNetwork -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Name "dsVnet" -AddressPrefix "10.0.0.0/16","ace:cab:deca::/48" -Subnet $subnet

#Create Network Interfaces (NICs)
$Ip4Config=New-AzNetworkInterfaceIpConfig -Name dsIp4Config -Subnet $vnet.subnets[0] -PrivateIpAddressVersion IPv4 -LoadBalancerBackendAddressPool $backendPoolv4 -PublicIpAddress  $RdpPublicIP_1
$Ip6Config=New-AzNetworkInterfaceIpConfig -Name dsIp6Config -Subnet $vnet.subnets[0] -PrivateIpAddressVersion IPv6 -LoadBalancerBackendAddressPool $backendPoolv6
$NIC_1 = New-AzNetworkInterface -Name "dsNIC1" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location  -NetworkSecurityGroupId $nsg.Id -IpConfiguration $Ip4Config,$Ip6Config 
$Ip4Config=New-AzNetworkInterfaceIpConfig -Name dsIp4Config -Subnet $vnet.subnets[0] -PrivateIpAddressVersion IPv4 -LoadBalancerBackendAddressPool $backendPoolv4 -PublicIpAddress  $RdpPublicIP_2
$NIC_2 = New-AzNetworkInterface -Name "dsNIC2" -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location  -NetworkSecurityGroupId $nsg.Id -IpConfiguration $Ip4Config,$Ip6Config 


#Create Virtual Machines
$cred = get-credential -Message "DUAL STACK VNET SAMPLE:  Please enter the Administrator credential to log into the VM's"

$vmsize = "Standard_A2"
$ImagePublisher = "MicrosoftWindowsServer"
$imageOffer = "WindowsServer"
$imageSKU = "2016-Datacenter"

$vmName= "dsVM1"
$VMconfig1 = New-AzVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $avset.Id 3> $null | Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent 3> $null | Set-AzVMSourceImage -PublisherName $ImagePublisher -Offer $imageOffer -Skus $imageSKU -Version "latest" 3> $null | Set-AzVMOSDisk -Name "$vmName.vhd" -CreateOption fromImage  3> $null | Add-AzVMNetworkInterface -Id $NIC_1.Id  3> $null 
$VM1 = New-AzVM -ResourceGroupName $rg.ResourceGroupName  -Location $rg.Location  -VM $VMconfig1 

$vmName= "dsVM2"
$VMconfig2 = New-AzVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $avset.Id 3> $null | Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent 3> $null | Set-AzVMSourceImage -PublisherName $ImagePublisher -Offer $imageOffer -Skus $imageSKU -Version "latest" 3> $null | Set-AzVMOSDisk -Name "$vmName.vhd" -CreateOption fromImage  3> $null | Add-AzVMNetworkInterface -Id $NIC_2.Id  3> $null 
$VM2 = New-AzVM -ResourceGroupName $rg.ResourceGroupName  -Location $rg.Location  -VM $VMconfig2 

