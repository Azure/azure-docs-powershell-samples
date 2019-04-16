# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
# ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.
#
# Copyright (c) 2019 Microsoft Corporation. All rights reserved.
#
# Dual-Stack VNET with 2 VMs.ps1
#	Deploys Dual-stack (IPv4+IPv6) VNET with 2 VM's and BASIC Load Balancer with IPv4 and IPv6 Public IP's
#	See below for default names, subnet ranges, etc. and the parameters you can use to override the defaults 
#
#The minimum required Azure Powershell version for working with all Dual-stack virtual network features is:  TBD
#NOTE:  Warnings about future Azure Powershell API changes have been suppressed in this script's output by sending warnings to null ( 3> $null ) on some commands  


#Typical Usage:
#     '.\Dual-Stack VNET with 2 VMs.ps1'   -location <Azure Region>  -rgName <Arbitrary name for existing or new azure resource group for this deployment>  [many optional parameters as listed below]
#	If you have more than one subscription, you can specify which to use for this deployment with the -subscriptionName argument
#
# If you expect to run this script repeatedly, you may wish to connect your powershell session to Azure using these commands: 
#	connect-AzAccount...then follow the instructions to log in
#	get-AzSubscription...to show all your subscriptions
#	set-AzContext -Subscription <Subscription Name>...to chose a default subscription for this session
#	Then run '.\Dual-Stack VNET with 2 VMs.ps1' as above but add the parameter:   -triggerLogin $FALSE  


#Command Line Parameters
Param
(
    [Parameter(Mandatory=$true)] [string] $location = "",   #Azure Region for this deployment
    [Parameter(Mandatory=$true)] [string] $rgName = "",   #Resource Group Name
    [Parameter(Mandatory=$false)] [int] $NumberOfVMs =  2,
    [Parameter(Mandatory=$false)] [boolean] $triggerLogin = $true,  #performs Azure login and sets -subscritionName if provided
    [Parameter(Mandatory=$false)] [string] $subscriptionName = "",    #Subscription Name if other than your default subscription for this deployment 
    [Parameter(Mandatory=$false)] [string] $availabilitySetName = "dsAVset",       
    [Parameter(Mandatory=$false)] [string] $vnetName = "dsVNET",
    [Parameter(Mandatory=$false)] [array] $vnetAddressRanges = @("10.0.0.0/16","ace:cab:deca::/48"),    
    [Parameter(Mandatory=$false)] [string] $subnetName = "dsSubNET",  
    [Parameter(Mandatory=$false)] [string] $subnetV4AddressRange = "10.0.0.0/24",    
    [Parameter(Mandatory=$false)] [string] $subnetV6AddressRange = "ace:cab:deca:deed::/64",    
    [Parameter(Mandatory=$false)] [string] $publicIPName_v4 = "dsPublicIP_v4",
    [Parameter(Mandatory=$false)] [string] $publicIPName_v6 = "dsPublicIP_v6",
    [Parameter(Mandatory=$false)] [string] $RDP_PublicIPBaseName = "dsPublicIP_Maint",
    [Parameter(Mandatory=$false)] [string] $nicBaseName = "dsNIC",
    [Parameter(Mandatory=$false)] [string] $vmBaseName = "dsVM",
    [Parameter(Mandatory=$false)] [string] $lbName = "dsLB",   #Load Balancer Name
    [Parameter(Mandatory=$false)] [string] $vmsize = "Standard_A2",	
    [Parameter(Mandatory=$false)] [string] $ImagePublisher = "MicrosoftWindowsServer",
    [Parameter(Mandatory=$false)] [string] $imageOffer = "WindowsServer",
    [Parameter(Mandatory=$false)] [string] $imageSKU = "2016-Datacenter"
)

#Constants
$newStorageAccountName= "dsStorage" + (new-guid).toString   #A globally unique storage account name to be used with this deployment


#Log into Azure (unless the -triggerLogin parameter is set to $FALSE)
if ($triggerLogin)
{
    connect-AzAccount   1>$null
    #get-AzSubscription
    
    if ($subscriptionName )
    {
    	set-AzContext -Subscription $subscriptionName   1>$null
    	Write-host `nContext/Subscription for this deployment is:  
	get-AzContext
    }
	else 
	{
		Write-host Using default context as -subscriptionName was not specified.
		Write-host Current context is:  
		get-AzContext
	}
}

#Prompt the user for admin credentials to be applied to the VM's
$VmAdminCred = get-credential -Message "DUAL-STACK VNET SAMPLE:  Please enter the Administrator credential that will be added to the VM's you're about to deploy"

#Resource Group
$rg = Get-AzResourceGroup -Name $rgName -Location $location  -ErrorAction SilentlyContinue  #Attempt to use an existing resource group (if its already been created)
if (!$rg)
{
    Write-Host Creating New Resource Group:  $rgName
    $rg = New-AzResourceGroup -Name $rgName -Location $location    #Otherwise, create a new resource group
    
}

#Public IP's for RDP (maintenance) connections to the VMs
Write-Host "Creating Public IP's for Maintenance (RDP)"
$PIParray = @()
For ($PIPindex=0; $PIPindex -lt $NumberOfVMs; $PIPindex++)  
{
	$PIPName= $RDP_PublicIPBaseName+$PIPindex
	$PIParray += New-AzPublicIpAddress -Name $PIPName -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic -IpAddressVersion IPv4 3> $null 
}
	

#Load Balancer 
$lb= Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
if (!$lb)
{
Write-Host "Creating Public IP's for Load Balancer"
$PublicIP_v4 = New-AzPublicIpAddress -Name $publicIPName_v4 -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic -IpAddressVersion IPv4 3> $null 
$PublicIP_v6 = New-AzPublicIpAddress -Name $publicIPName_v6 -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AllocationMethod Dynamic -IpAddressVersion IPv6 3> $null 

Write-Host -noNewLine "Creating BASIC Load Balancer..."
$frontendIPv4 = New-AzLoadBalancerFrontendIpConfig   -Name "dsLbFrontEnd_v4"   -PublicIpAddress $PublicIP_v4
$frontendIPv6 = New-AzLoadBalancerFrontendIpConfig   -Name "dsLbFrontEnd_v6"   -PublicIpAddress $PublicIP_v6
$backendPoolv4 = New-AzLoadBalancerBackendAddressPoolConfig -Name "dsLbBackEndPool_v4"
$backendPoolv6 = New-AzLoadBalancerBackendAddressPoolConfig -Name "dsLbBackEndPool_v6"

#Add a health probe if needed 
#$probe = New-AzLoadBalancerProbeConfig   -Name "dsHealthProbe"   -RequestPath myhealthcheck2.aspx   -Protocol http   -Port 80   -IntervalInSeconds 16   -ProbeCount 2
# TBD - IPv6 probe example

#LB Rules which maps TCP Port 80 straight across from front to backend IPv4 pools 
$lbrule_v4 = New-AzLoadBalancerRuleConfig `
  -Name "dsLBrule_v4" `
  -FrontendIpConfiguration $frontendIPv4 `
  -BackendAddressPool $backendPoolv4 `
  -Protocol Tcp `
  -FrontendPort 80 `
  -BackendPort 80 

#LB Rules which maps TCP Port 80 straight across from front to backend IPv6 pools
$lbrule_v6 = New-AzLoadBalancerRuleConfig `
  -Name "dsLBrule_v6" `
  -FrontendIpConfiguration $frontendIPv6 `
  -BackendAddressPool $backendPoolv6 `
  -Protocol Tcp `
  -FrontendPort 80 `
  -BackendPort 80   
  
#Have NOT included a NAT rule but here's an example of how you create one in PS: 
#	$natrule1 = New-AzLoadBalancerInboundNatRuleConfig -Name 'myLoadBalancerRDP1' -FrontendIpConfiguration $frontendIP -Protocol tcp -FrontendPort 4221 -BackendPort 3389

#Creates the BASIC load balancer (not Standard LB) using the components defined above
$lb = New-AzLoadBalancer `
-ResourceGroupName $rg.ResourceGroupName  `
-Name $lbName `
-Location $rg.Location `
-Sku "Basic" `
-FrontendIpConfiguration $frontendIPv4,$frontendIPv6 `
-BackendAddressPool $backendPoolv4,$backendPoolv6 `
-LoadBalancingRule $lbrule_v4,$lbrule_v6   3> $null 
# -InboundNatRule $natrule1,$natrule2 `
# -Probe $probe 
write-host Complete
}

#Availability Set
$avset = Get-AzAvailabilitySet -Name $availabilitySetName -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
if (!$avset)
{
    Write-Host "Creating Availability Set"
    $avset = New-AzAvailabilitySet -Name $availabilitySetName -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -PlatformUpdateDomainCount 2 -PlatformFaultDomainCount 2 -Sku Aligned
}

#Network Security Group
$nsg = Get-AzNetworkSecurityGroup -Name nsg1 -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
if (!$nsg)
{
    Write-Host "Creating NSG"
    $ruleinHttp = New-AzNetworkSecurityRuleConfig -Name allowhttpin -Description "Allow HTTP In" -Access Allow -Protocol TCP -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange 80 -DestinationAddressPrefix * -DestinationPortRange 80
    $ruleinRdp = New-AzNetworkSecurityRuleConfig -Name allowrdpin -Description "Allow RDP In" -Access Allow -Protocol TCP -Direction Inbound -Priority 200 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
    $ruleout = New-AzNetworkSecurityRuleConfig -Name allowallout -Description "Allow All Out" -Access Allow -Protocol * -Direction Outbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *
    $nsg = New-AzNetworkSecurityGroup -Name dsNSG1 -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -SecurityRules $ruleinHttp,$ruleinRdp,$ruleout  3> $null 
}

#Virtual Network
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
if (!$vnet)
{
    Write-Host Creating VNET:  $vnetName
    # Using a single, dual-stack SUBNET with both IPv4 and IPv6 address ranges
    $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetV4AddressRange,$subnetV6AddressRange
    $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -AddressPrefix $vnetAddressRanges -Subnet $subnet  3> $null
}

#Network Interfaces (NIC's)
Write-Host Creating Network Interfaces:
$NICarray = @()
For ($NICindex=0; $NICindex -lt $NumberOfVMs; $NICindex++)  
{
	$nicName= $nicBaseName+$NICindex
	$Ip4Config=New-AzNetworkInterfaceIpConfig -Name dsIp4Config -Subnet $vnet.subnets[0] -PrivateIpAddressVersion IPv4 -LoadBalancerBackendAddressPool $backendPoolv4  -PublicIpAddress $PIParray[$NICindex]
	$Ip6Config=New-AzNetworkInterfaceIpConfig -Name dsIp6Config -Subnet $vnet.subnets[0] -PrivateIpAddressVersion IPv6 -LoadBalancerBackendAddressPool $backendPoolv6
	$NICarray +=  New-AzNetworkInterface -Name $nicName -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -NetworkSecurityGroupId $nsg.Id -IpConfiguration $Ip4Config,$Ip6Config 3> $null 
	Write-Host  "   " $NICarray[$NICindex].Name created
}

#Virtual Machines
Write-Host "Creating VM's:  "
$VMconfigArray= @()
$VMarray= @()
For ($VMconfigIndex=0; $VMconfigIndex -lt $NumberOfVMs; $VMconfigIndex++)  
{
	$vmName= $vmBaseName+$VMconfigIndex
	$VMconfigArray += New-AzVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $avset.Id 3> $null | Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $VmAdminCred -ProvisionVMAgent 3> $null | Set-AzVMSourceImage -PublisherName $ImagePublisher -Offer $imageOffer -Skus $imageSKU -Version "latest" 3> $null | Set-AzVMOSDisk -Name "$vmName.vhd" -CreateOption fromImage  3> $null | Add-AzVMNetworkInterface -Id $NICarray[$VMconfigIndex].Id  3> $null 
	Write-Host  -noNewLine "   " Creating $VMconfigArray[$VMconfigIndex].Name ...
	$VMarray += New-AzVM -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -VM $VMconfigArray[$VMconfigIndex] 3> $null 
	Write-Host Complete
}

#Deployment is now complete
Write-Host  `n Deployment is complete (get-date)

#Get all Network Interface Objects in the resource group to summarize the IP's used in the deployment
 $NICsInRG= get-AzNetworkInterface -resourceGroupName $rgName
  
write-host `nSummary of IPs in this Deployment:
write-host ******************************************
foreach ($NIC in $NICsInRG)
{
	$VMid= $NIC.virtualmachine.id
	$VMnamebits= $VMid.split("/")
	$VMname= $VMnamebits[($VMnamebits.count-1)]
	write-host `nPrivate IP addresses for $VMname 
	$IPconfigsInNIC= $NIC.IPconfigurations
	foreach ($IPconfig in $IPconfigsInNIC)
		{
			$IPaddress= $IPconfig.privateipaddress
			write-host "    "$IPaddress  
			IF ($IPconfig.PublicIpAddress.ID) 
				{
				$IDbits= ($IPconfig.PublicIpAddress.ID).split("/")
				$PipName= $IDbits[($IDbits.count-1)]
				$PipObject= get-azPublicIpAddress -name $PipName -resourceGroup $rgName
				write-host "    "RDP address:  $PipObject.IpAddress
				}
		}
}
  
  write-host `nPublic IP addresses on Load Balancer:
  (get-AzpublicIpAddress -resourcegroupname $rgName | where { $_.name -notlike $RDP_PublicIPBaseName+"*" }).IpAddress

#End Of Script


