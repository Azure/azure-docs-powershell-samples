# Create a resource group.
New-AzureRmResourceGroup -Name myResourceGroup -Location westeurope

# Create a subnet configuration.
$subnetconfig = New-AzureRmVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 192.168.1.0/24

# Create a virtual network.
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName myResourceGroup -Location westeurope -Name MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetconfig

# Create a public IP address and specify a DNS name.
$pip = New-AzureRmPublicIpAddress -ResourceGroupName myResourceGroup -Location westeurope -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4

# Create an inbound network security group rule for port 22.
$nsgrule = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow

# Create a network security group.
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName myResourceGroup -Location westeurope -Name myNetworkSecurityGroup -SecurityRules $nsgrule

# Get subnet object.
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

# Create a virtual network card and associate with public IP address and NSG.
$nic = New-AzureRmNetworkInterface -ResourceGroupName myResourceGroup -Location westeurope -Name myNic -Subnet $subnet -NetworkSecurityGroup $nsg -PublicIpAddress $pip

# Create a virtual machine configuration. 
$vmconfig = New-AzureRmVMConfig -VMName myVM -VMSize Standard_D1 | Set-AzureRmVMOperatingSystem -Windows -ComputerName myVM -Credential $creds | Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 14.04.2-LTS -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id

# Create a virtual machine
New-AzureRmVM -ResourceGroupName myResourceGroup -Location westeurope -VM $vmconfig

# Install Docker and start container.

$PublicSettings = '{"docker": {"port": "2375"},"compose": {"web": {"image": "nginx","ports": ["80:80"]}}}' | ConvertTo-Json

Set-AzureRmVMExtension -ExtensionName "Docker" `
    -ResourceGroupName "myResourceGroup" `
    -VMName "myVM" `
    -Publisher "Microsoft.Azure.Extensions" `
    -ExtensionType "DockerExtension" `
    -TypeHandlerVersion 1.0 `
    -Settings $PublicSettings `
    -Location westeurope