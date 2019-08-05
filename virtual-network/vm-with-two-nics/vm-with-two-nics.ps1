# Variables for common values
$rgName='MyResourceGroup'
$location='eastus'

# Create user object
$cred = Get-Credential -Message 'Enter a username and password for the virtual machine.'

# Create a resource group.
New-AzResourceGroup -Name $rgName -Location $location

# Create a virtual network with a front-end subnet and back-end subnet.
$fesubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-FrontEnd' -AddressPrefix '10.0.1.0/24'
$besubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-BackEnd' -AddressPrefix '10.0.2.0/24'
$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'MyVnet' -AddressPrefix '10.0.0.0/16' `
  -Location $location -Subnet $fesubnet, $besubnet

# Create NSG rules to allow HTTP & HTTPS traffic inbound.
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTP-ALL' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

$rule2 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTPS-All' -Description 'Allow HTTPS' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

# Create an NSG rule to allow RDP traffic from the Internet to the front-end subnet.
$rule2 = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description "Allow RDP" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 300 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389

# Create a network security group (NSG) for the front-end subnet.
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
  -Name "MyNsg-FrontEnd" -SecurityRules $rule1,$rule2,$rule3

# Associate the front-end NSG to the front-end subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-FrontEnd' `
  -AddressPrefix 10.0.1.0/24 -NetworkSecurityGroup $nsgfe

# Create an NSG rule to block all outbound traffic from the back-end subnet to the Internet (inbound blocked by default).
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Deny-Internet-All' -Description 'Deny Internet All' `
  -Access Deny -Protocol Tcp -Direction Outbound -Priority 300 `
  -SourceAddressPrefix * -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange *

# Create a network security group for back-end subnet.
$nsgbe = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
  -Name 'MyNsg-BackEnd' -SecurityRules $rule1

# Associate the back-end NSG to the back-end subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-BackEnd' `
  -AddressPrefix 10.0.2.0/24 -NetworkSecurityGroup $nsgbe

# Create a public IP addresses for the VM front-end network interface.
$publicipvm = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-FrontEnd' `
  -location $location -AllocationMethod Dynamic


# Create a network interface for the VM attached to the front-end subnet.
$nicVMfe = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'MyNic-FrontEnd' -PublicIpAddress $publicipvm -Subnet $vnet.Subnets[0]

# Create a network interface for the VM attached to the back-end subnet.
$nicVMbe = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'MyNic-BackEnd' -Subnet $vnet.Subnets[1]

# Create the VM with both the FrontEnd and BackEnd NICs.
$vmConfig = New-AzVMConfig -VMName 'MyVm' -VMSize 'Standard_DS2' | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'MyVm' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
  -Skus '2016-Datacenter' -Version 'latest'
    
$vmconfig = Add-AzVMNetworkInterface -VM $vmConfig -id $nicVMfe.Id -Primary
$vmconfig = Add-AzVMNetworkInterface -VM $vmConfig -id $nicVMbe.Id

# Create a virtual machine
$vm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

