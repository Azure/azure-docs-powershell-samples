# OMS Id and OMS key
$omsid=<Replace with your OMS Id>
$omskey=<Replace with your OMS key>

# Variables for common values
$resourceGroup = "myResourceGroup"
$location = "westeurope"
$vmName = "myVM"

# Definer user name and blank password
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)

# Create a resource group.
New-AzureRmResourceGroup -Name $resourceGroup -Location $location

# Create a subnet configuration
$subnetconfig = New-AzureRmVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetconfig

# Create a public IP address and specify a DNS name.
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name myNetworkSecurityGroup -SecurityRules $nsgrule

# Get subnet object
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Location $location -Name myNic `
  -Subnet $subnet -NetworkSecurityGroup $nsg -PublicIpAddress $pip

# Create a virtual machine configuration
$vmconfig = New-AzureRmVMConfig -VMName $vmname -VMSize Standard_D1 | `
Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmname -Credential $cred -DisablePasswordAuthentication | `
Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 14.04.2-LTS -Version latest | `
Add-AzureRmVMNetworkInterface -Id $nic.Id

# Configure SSH Keys
$sshpubickey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
Add-AzureRmVMSshPublicKey -VM $vmconfig -KeyData $sshpubickey -Path "/home/azureuser/.ssh/authorized_keys"

# Create a virtual machine
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vmconfig

# Install and configure the OMS agent
$PublicSettings = New-Object psobject | Add-Member -PassThru NoteProperty workspaceId $omsid | ConvertTo-Json
$protectedsettings = New-Object psobject | Add-Member -PassThru NoteProperty workspaceKey $omskey | ConvertTo-Json

Set-AzureRmVMExtension -ExtensionName "OMS" -ResourceGroupName $resourceGroup -VMName $vmName `
  -Publisher "Microsoft.EnterpriseCloud.Monitoring" -ExtensionType "OmsAgentForLinux" `
  -TypeHandlerVersion 1.0 -SettingString $PublicSettings ` -ProtectedSettingString $protectedsettings `
  -Location $location