# Variables for common values
$rgName='MyResourceGroup'
$location='eastus'

# Create user object
$cred = Get-Credential -Message 'Enter a username and password for the virtual machine.'

# Create a resource group.
New-AzureRmResourceGroup -Name $rgName -Location $location

# Create a virtual network, a front-end subnet, a back-end subnet, and a DMZ subnet.
$fesubnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'MySubnet-FrontEnd' -AddressPrefix 10.0.1.0/24
$besubnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'MySubnet-BackEnd' -AddressPrefix 10.0.2.0/24
$dmzsubnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'MySubnet-Dmz' -AddressPrefix 10.0.0.0/24

$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name 'MyVnet' -AddressPrefix 10.0.0.0/16 `
  -Location $location -Subnet $fesubnet, $besubnet, $dmzsubnet

# Create NSG rules to allow HTTP & HTTPS traffic inbound.
$rule1 = New-AzureRmNetworkSecurityRuleConfig -Name 'Allow-HTTP-ALL' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

$rule2 = New-AzureRmNetworkSecurityRuleConfig -Name 'Allow-HTTPS-All' -Description 'Allow HTTPS' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 443

# Create a network security group (NSG) for the front-end subnet.
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
-Name 'MyNsg-FrontEnd' -SecurityRules $rule1,$rule2

# Associate the front-end NSG to the front-end subnet.
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-FrontEnd' `
  -AddressPrefix '10.0.1.0/24' -NetworkSecurityGroup $nsg

# Create a public IP address for the firewall VM.
$publicip = New-AzureRmPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIP-Firewall' `
  -location $location -AllocationMethod Dynamic

# Create a NIC for the firewall VM and enable IP forwarding.
$nicVMFW = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location -Name 'MyNic-Firewall' `
  -PublicIpAddress $publicip -Subnet $vnet.Subnets[2] -EnableIPForwarding

#Create a firewall VM to accept all traffic between the front and back-end subnets.
$vmConfig = New-AzureRmVMConfig -VMName 'MyVm-Firewall' -VMSize Standard_DS2 | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName 'MyVm-Firewall' -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nicVMFW.Id
    
$vm = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

# Create a route for traffic from the front-end to the back-end subnet through the firewall VM.
$route = New-AzureRmRouteConfig -Name 'RouteToBackEnd' -AddressPrefix 10.0.2.0/24 `
  -NextHopType VirtualAppliance -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIpAddress

# Create a route for traffic from the front-end subnet to the Internet through the firewall VM.
$route2 = New-AzureRmRouteConfig -Name 'RouteToInternet' -AddressPrefix 0.0.0.0/0 `
  -NextHopType VirtualAppliance -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIpAddress

# Create route table for the FrontEnd subnet.
$routeTableFEtoBE = New-AzureRmRouteTable -Name 'MyRouteTable-FrontEnd' -ResourceGroupName $rgName `
  -location $location -Route $route, $route2

# Associate the route table to the FrontEnd subnet.
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-FrontEnd' -AddressPrefix 10.0.1.0/24 `
  -NetworkSecurityGroup $nsg -RouteTable $routeTableFEtoBE
  
# Create a route for traffic from the back-end subnet to the front-end subnet through the firewall VM.
$route = New-AzureRmRouteConfig -Name 'RouteToFrontEnd' -AddressPrefix '10.0.1.0/24' -NextHopType VirtualAppliance `
  -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIPAddress

# Create a route for traffic from the back-end subnet to the Internet through the firewall VM.
$route2 = New-AzureRmRouteConfig -Name 'RouteToInternet' -AddressPrefix '0.0.0.0/0' -NextHopType VirtualAppliance `
  -NextHopIpAddress $nicVMFW.IpConfigurations[0].PrivateIPAddress

# Create route table for the BackEnd subnet.
$routeTableBE = New-AzureRmRouteTable -Name 'MyRouteTable-BackEnd' -ResourceGroupName $rgName `
  -location $location -Route $route, $route2

# Associate the route table to the BackEnd subnet.
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-BackEnd' `
  -AddressPrefix '10.0.2.0/24' -RouteTable $routeTableBE