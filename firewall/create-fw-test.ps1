
#ResourceGroup name and location
$RG="AzfwSampleScriptEastUS"
$Location="East US"

#User credentials for JumpBox and Server VMs
$securePassword = ConvertTo-SecureString 'P@$$W0rd010203' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("AzfwUser", $securePassword)


#Create new RG
New-AzResourceGroup -Name $RG -Location $Location

#Create Vnet
$VnetName=$RG+"Vnet"
New-AzVirtualNetwork -ResourceGroupName $RG -Name $VnetName -AddressPrefix 192.168.0.0/16 -Location $Location

#Configure subnets
$vnet = Get-AzVirtualNetwork -ResourceGroupName $RG -Name $VnetName
Add-AzVirtualNetworkSubnetConfig -Name AzureFirewallSubnet -VirtualNetwork $vnet -AddressPrefix 192.168.1.0/24
Add-AzVirtualNetworkSubnetConfig -Name JumpBoxSubnet -VirtualNetwork $vnet -AddressPrefix 192.168.0.0/24
Add-AzVirtualNetworkSubnetConfig -Name ServersSubnet -VirtualNetwork $vnet -AddressPrefix 192.168.2.0/24
Set-AzVirtualNetwork -VirtualNetwork $vnet

#create Public IP for jumpbox and LB
$LBPipName = $RG + "PublicIP"
$LBPip = New-AzPublicIpAddress -Name $LBPipName  -ResourceGroupName $RG -Location $Location -AllocationMethod Static -Sku Standard
$JumpBoxpip = New-AzPublicIpAddress -Name "JumpHostPublicIP"  -ResourceGroupName $RG -Location $Location -AllocationMethod Static -Sku Basic

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

# Create a network security group
$NsgName = $RG+"NSG"
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $RG -Location $Location -Name $NsgName -SecurityRules $nsgRuleRDP

#Create jumpbox
$vnet = Get-AzVirtualNetwork -ResourceGroupName $RG -Name $VnetName
$JumpBoxSubnetId = $vnet.Subnets[1].Id
# Create a virtual network card and associate with jumpbox public IP address
$JumpBoxNic = New-AzNetworkInterface -Name JumpBoxNic -ResourceGroupName $RG -Location $Location -SubnetId $JumpBoxSubnetId -PublicIpAddressId $JumpBoxpip.Id -NetworkSecurityGroupId $nsg.Id
$JumpBoxConfig = New-AzVMConfig -VMName JumpBox -VMSize Standard_DS1_v2 | Set-AzVMOperatingSystem -Windows -ComputerName JumpBox -Credential $cred | Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version latest | Add-AzVMNetworkInterface -Id $JumpBoxNic.Id
New-AzVM -ResourceGroupName $RG -Location $Location -VM $JumpBoxConfig

#Create Server VM
$ServersSubnetId = $vnet.Subnets[2].Id
$ServerVmNic = New-AzNetworkInterface -Name ServerVmNic -ResourceGroupName $RG -Location $Location -SubnetId $ServersSubnetId
$ServerVmConfig = New-AzVMConfig -VMName ServerVm -VMSize Standard_DS1_v2 | Set-AzVMOperatingSystem -Windows -ComputerName ServerVm -Credential $cred | Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version latest | Add-AzVMNetworkInterface -Id $ServerVmNic.Id
New-AzVM -ResourceGroupName $RG -Location $Location -VM $ServerVmConfig

#Create AZFW
$GatewayName = $RG + "Azfw"
$Azfw = New-AzFirewall -Name $GatewayName -ResourceGroupName $RG -Location $Location -VirtualNetworkName $vnet.Name -PublicIpName $LBPip.Name

#Add a rule to allow *microsoft.com
$Azfw = Get-AzFirewall -ResourceGroupName $RG
$Rule = New-AzFirewallApplicationRule -Name R1 -Protocol "http:80","https:443" -TargetFqdn "*microsoft.com"
$RuleCollection = New-AzFirewallApplicationRuleCollection -Name RC1 -Priority 100 -Rule $Rule -ActionType "Allow"
$Azfw.ApplicationRuleCollections = $RuleCollection
Set-AzFirewall -AzureFirewall $Azfw

#Create UDR rule
$Azfw = Get-AzFirewall -ResourceGroupName $RG
$AzfwRouteName = $RG + "AzfwRoute"
$AzfwRouteTableName = $RG + "AzfwRouteTable"
$IlbCA = $Azfw.IpConfigurations[0].PrivateIPAddress
$AzfwRoute = New-AzRouteConfig -Name $AzfwRouteName -AddressPrefix 0.0.0.0/0 -NextHopType VirtualAppliance -NextHopIpAddress $IlbCA
$AzfwRouteTable = New-AzRouteTable -Name $AzfwRouteTableName -ResourceGroupName $RG -location $Location -Route $AzfwRoute

#associate to Servers Subnet
$vnet.Subnets[2].RouteTable = $AzfwRouteTable
Set-AzVirtualNetwork -VirtualNetwork $vnet
