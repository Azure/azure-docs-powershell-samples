# Variables for common values
$resourceGroup = "myResourceGroup"
$location = "eastus"
$vmName = "myVM"

# Create credentials for the administrator account
$cred = Get-Credential

# Create a resource group
New-AzResourceGroup -ResourceGroupName myResourceGroup -Location eastus

# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name mySubnet `
  -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name myVnet `
  -AddressPrefix 192.168.0.0/16 `
  -Subnet $subnetConfig

# Create a public IP address
$pip = New-AzPublicIpAddress `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -AllocationMethod Static `
  -Name myPublicIPAddress

# Create a network security group rule for port 80
$nsgRule = New-AzNetworkSecurityRuleConfig `
  -Name myNSGRule `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow

# Create a network security group using the rule
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name myNetworkSecurityGroup `
  -SecurityRules $nsgRule

# Create a network interface
$nic = New-AzNetworkInterface `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name myNic `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Base64 encode the commands to run on the VM
$encoded = [System.Text.Encoding]::UTF8.GetBytes("Add-WindowsFeature Web-Server; Add-Content -Path 'C:\inetpub\wwwroot\Default.htm' -Value 'Hello World from myVM'")
$etext = [System.Convert]::ToBase64String($encoded)

# Create a VM configuration object
$vm = New-AzVMConfig `
  -VMName $vmName `
  -VMSize Standard_D1

# Configure the operating system for the VM using the credentials and encoded commands
$vm = Set-AzVMOperatingSystem `
  -VM $vm `
  -Windows `
  -ComputerName myVM `
  -Credential $cred `
  -CustomData $etext `
  -ProvisionVMAgent `
  -EnableAutoUpdate

# Define the image to use for the VM
$vm = Set-AzVMSourceImage `
  -VM $vm `
  -PublisherName MicrosoftWindowsServer `
  -Offer WindowsServer `
  -Skus 2016-Datacenter `
  -Version latest

# Configure the OS disk for the VM
$vm = Set-AzVMOSDisk `
  -VM $vm `
  -Name myOsDisk `
  -StorageAccountType StandardLRS `
  -DiskSizeInGB 128 `
  -CreateOption FromImage `
  -Caching ReadWrite

# Get the Id of the network interface and add it to the VM configuration
$nic = Get-AzNetworkInterface `
  -ResourceGroupName $resourceGroup `
  -Name myNic
$vm = Add-AzVMNetworkInterface `
  -VM $vm `
  -Id $nic.Id

# Create a VM
New-AzVM -ResourceGroupName $resourceGroup `
  -Location eastus `
  -VM $vm

# Run the encoded commands on the VM to install IIS
Set-AzVMExtension -ResourceGroupName $resourceGroup `
  -ExtensionName IIS `
  -VMName $vmName `
  -Publisher Microsoft.Compute `
  -ExtensionType CustomScriptExtension `
  -TypeHandlerVersion 1.4 `
  -SettingString '{"commandToExecute":"powershell \"[System.Text.Encoding]::UTF8.GetString([System.convert]::FromBase64String((Get-Content C:\\AzureData\\CustomData.bin))) | Out-File .\\command.ps1; powershell.exe .\\command.ps1\""}' `
  -Location $location
