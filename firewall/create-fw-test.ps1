#ResourceGroup name and location
$RG="AzfwSampleScriptEastUS"
$Location="East US"

#User credentials for JumpBox and Server VMs
$securePassword = ConvertTo-SecureString 'P@$$W0rd010203' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("AzfwUser", $securePassword)


#Create new RG
New-AzureRmResourceGroup -Name $RG -Location $Location

#Create Vnet
$VnetName=$RG+"Vnet"
New-AzureRmVirtualNetwork -ResourceGroupName $RG -Name $VnetName -AddressPrefix 192.168.0.0/16 -Location $Location

#Configure subnets
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RG -Name $VnetName
Add-AzureRmVirtualNetworkSubnetConfig -Name AzureFirewallSubnet -VirtualNetwork $vnet -AddressPrefix 192.168.1.0/24
Add-AzureRmVirtualNetworkSubnetConfig -Name JumpBox -VirtualNetwork $vnet -AddressPrefix 192.168.0.0/24
Add-AzureRmVirtualNetworkSubnetConfig -Name ServersSubnet -VirtualNetwork $vnet -AddressPrefix 192.168.2.0/24
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

#create Public IP for jumpbox and LB
$LBPipName = $RG + "PublicIP"
$LBPip = New-AzureRmPublicIpAddress -Name $LBPipName  -ResourceGroupName $RG -Location $Location -AllocationMethod Static -Sku Standard
$JumpBoxpip = New-AzureRmPublicIpAddress -Name "JumpHostPublicIP"  -ResourceGroupName $RG -Location $Location -AllocationMethod Static -Sku Basic

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

# Create a network security group
$NsgName = $RG+"NSG"
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG -Location $Location -Name $NsgName -SecurityRules $nsgRuleRDP

#Create jumpbox
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $RG -Name $VnetName
$DefaultSubnetId = $vnet.Subnets[1].Id
# Create a virtual network card and associate with jumpbox public IP address
$JumpBoxNic = New-AzureRmNetworkInterface -Name JumpBoxNic -ResourceGroupName $RG -Location $Location -SubnetId $DefaultSubnetId -PublicIpAddressId $JumpBoxpip.Id -NetworkSecurityGroupId $nsg.Id
$JumpBoxConfig = New-AzureRmVMConfig -VMName JumpBox -VMSize Standard_DS1_v2 | Set-AzureRmVMOperatingSystem -Windows -ComputerName JumpBox -Credential $cred | Set-AzureRmVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version latest | Add-AzureRmVMNetworkInterface -Id $JumpBoxNic.Id
New-AzureRmVM -ResourceGroupName $RG -Location $Location -VM $JumpBoxConfig

#Create Server VM
$ServersSubnetId = $vnet.Subnets[2].Id
$ServerVmNic = New-AzureRmNetworkInterface -Name ServerVmNic -ResourceGroupName $RG -Location $Location -SubnetId $ServersSubnetId
$ServerVmConfig = New-AzureRmVMConfig -VMName ServerVm -VMSize Standard_DS1_v2 | Set-AzureRmVMOperatingSystem -Windows -ComputerName ServerVm -Credential $cred | Set-AzureRmVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version latest | Add-AzureRmVMNetworkInterface -Id $ServerVmNic.Id
New-AzureRmVM -ResourceGroupName $RG -Location $Location -VM $ServerVmConfig

#Create AZFW
$GatewayName = $RG + "Azfw"
$Azfw = New-AzureRmFirewall -Name $GatewayName -ResourceGroupName $RG -Location $Location -VirtualNetworkName $vnet.Name

#Add a rule to allow *microsoft.com
$Azfw = Get-AzureRmFirewall -ResourceGroupName $RG
$Rule = New-AzureRmFirewallApplicationRule -Name R1 -Protocol "http:80","https:443" -TargetFqdn "*microsoft.com"
$RuleCollection = New-AzureRmFirewallApplicationRuleCollection -Name RC1 -Priority 100 -Rule $Rule -ActionType "Allow"
$Azfw.ApplicationRuleCollections = $RuleCollection
Set-AzureRmFirewall -AzureFirewall $Azfw

#Create UDR rule
$Azfw = Get-AzureRmFirewall -ResourceGroupName $RG
$AzfwRouteName = $RG + "AzfwRoute"
$AzfwRouteTableName = $RG + "AzfwRouteTable"
$IlbCA = $Azfw.IpConfigurations[0].PrivateIPAddress
$AzfwRoute = New-AzureRmRouteConfig -Name $AzfwRouteName -AddressPrefix 0.0.0.0/0 -NextHopType VirtualAppliance -NextHopIpAddress $IlbCA
$AzfwRouteTable = New-AzureRmRouteTable -Name $AzfwRouteTableName -ResourceGroupName $RG -location $Location -Route $AzfwRoute

#associate to Servers Subnet
$vnet.Subnets[2].RouteTable = $SecGwRouteTable
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
