# Define the resource group name and location
$myResourceGroup = "myResourceGroup"
$myLocation = "East US"

# Provide your own secure password for use with the VM instances
$securePassword = "P@ssword!"
$adminUsername = "azureuser"

# Create a resource group
New-AzureRmResourceGroup -ResourceGroupName $myResourceGroup -Location $myLocation

# Create a virtual network subnet
$subnet = New-AzureRmVirtualNetworkSubnetConfig `
  -Name "mySubnet" `
  -AddressPrefix 10.0.0.0/24

# Create a virtual network
$vnet = New-AzureRmVirtualNetwork `
  -ResourceGroupName $myResourceGroup `
  -Name "myVnet" `
  -Location $myLocation `
  -AddressPrefix 10.0.0.0/16 `
  -Subnet $subnet

# Create a public IP address
$publicIP = New-AzureRmPublicIpAddress `
  -ResourceGroupName $myResourceGroup `
  -Location $myLocation `
  -AllocationMethod Static `
  -Name "myPublicIP"

# Create a frontend and backend IP pool
$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig `
  -Name "myFrontEndPool" `
  -PublicIpAddress $publicIP
$backendPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "myBackEndPool"

# Create a Network Address Translation (NAT) pool
$inboundNATPool = New-AzureRmLoadBalancerInboundNatPoolConfig `
  -Name "myRDPRule" `
  -FrontendIpConfigurationId $frontendIP.Id `
  -Protocol TCP `
  -FrontendPortRangeStart 50001 `
  -FrontendPortRangeEnd 50010 `
  -BackendPort 3389

# Create the load balancer
$lb = New-AzureRmLoadBalancer `
  -ResourceGroupName $myResourceGroup `
  -Name "myLoadBalancer" `
  -Location $myLocation `
  -FrontendIpConfiguration $frontendIP `
  -BackendAddressPool $backendPool `
  -InboundNatPool $inboundNATPool

# Create IP address configurations
$ipConfig = New-AzureRmVmssIpConfig `
  -Name "myIPConfig" `
  -LoadBalancerBackendAddressPoolsId $lb.BackendAddressPools[0].Id `
  -LoadBalancerInboundNatPoolsId $inboundNATPool.Id `
  -SubnetId $vnet.Subnets[0].Id

# Create a config object
$vmssConfig = New-AzureRmVmssConfig `
  -Location $myLocation `
  -SkuCapacity 2 `
  -SkuName "Standard_DS2" `
  -UpgradePolicyMode Automatic

# Reference a virtual machine image from the gallery
Set-AzureRmVmssStorageProfile $vmssConfig `
  -ImageReferencePublisher "MicrosoftWindowsServer" `
  -ImageReferenceOffer "WindowsServer" `
  -ImageReferenceSku "2016-Datacenter" `
  -ImageReferenceVersion "latest"

# Set up information for authenticating with the virtual machine
Set-AzureRmVmssOsProfile $vmssConfig `
  -AdminUsername $adminUsername `
  -AdminPassword $securePassword `
  -ComputerNamePrefix "myVM"

# Attach the virtual network to the config object
Add-AzureRmVmssNetworkInterfaceConfiguration `
  -VirtualMachineScaleSet $vmssConfig `
  -Name "network-config" `
  -Primary $true `
  -IPConfiguration $ipConfig

# Add the first data disk to the scale set config
Add-AzureRmVmssDataDisk `
  -VirtualMachineScaleSet $vmssConfig `
  -CreateOption Empty `
  -Lun 1 `
  -DiskSizeGB 64

# Add the second data disk to the scale set config
Add-AzureRmVmssDataDisk `
  -VirtualMachineScaleSet $vmssConfig `
  -CreateOption Empty `
  -Lun 2 `
  -DiskSizeGB 128

# Create the scale set with the config object (this step might take a few minutes)
New-AzureRmVmss `
  -ResourceGroupName $myResourceGroup `
  -Name "myScaleSet" `
  -VirtualMachineScaleSet $vmssConfig

# Get scale set object
$vmss = Get-AzureRmVmss `
          -ResourceGroupName $myResourceGroup `
          -VMScaleSetName "myScaleSet"

# Attach a 128 GB data disk to LUN 3
Add-AzureRmVmssDataDisk `
  -VirtualMachineScaleSet $vmss `
  -CreateOption Empty `
  -Lun 3 `
  -DiskSizeGB 128

# Update the scale set to apply the change
Update-AzureRmVmss `
  -ResourceGroupName $myResourceGroup `
  -Name "myScaleSet" `
  -VirtualMachineScaleSet $vmss

$publicSettings = @{
  "fileUris" = (,"https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/prepare_vm_disks.ps1");
  "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File prepare_vm_disks.ps1"
}

# Use Custom Script Extension to prepare the attached data disks
Add-AzureRmVmssExtension -VirtualMachineScaleSet $vmss `
  -Name "customScript" `
  -Publisher "Microsoft.Compute" `
  -Type "CustomScriptExtension" `
  -TypeHandlerVersion 1.8 `
  -Setting $publicSettings

# Update the scale set and apply the Custom Script Extension to the VM instances
Update-AzureRmVmss `
  -ResourceGroupName $myResourceGroup `
  -Name "myScaleSet" `
  -VirtualMachineScaleSet $vmss
