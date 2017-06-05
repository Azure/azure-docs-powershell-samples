# Edit these global variables with you unique Key Vault name, resource group name and location
$keyVaultName = "myKeyVault"
$rgName = "myResourceGroup"
$location = "East US"

# Register the Key Vault provider and create a resource group
Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.KeyVault"
New-AzureRmResourceGroup -Location $location -Name $rgName

# Create a Key Vault and enable it for disk encryption
New-AzureRmKeyVault `
    -Location $location `
    -ResourceGroupName $rgName `
    -VaultName $keyVaultName `
    -EnabledForDiskEncryption

# Create a key in your Key Vault
Add-AzureKeyVaultKey `
    -VaultName $keyVaultName `
    -Name "myKey" `
    -Destination "Software"

# Create Azure Active Directory app and service principal
$appName = "My App"
$securePassword = "P@ssword!"
$app = New-AzureRmADApplication -DisplayName $appName `
    -HomePage "https://myapp.contoso.com" `
    -IdentifierUris "https://contoso.com/myapp" `
    -Password $securePassword
New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId

# Set permissions to allow your AAD service principal to read keys from Key Vault
Set-AzureRmKeyVaultAccessPolicy -VaultName $keyvaultName `
    -ServicePrincipalName $app.ApplicationId  `
    -PermissionsToKeys "all" `
    -PermissionsToSecrets "all"

# Define virtual networking for a new virtual machine
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
    -Name mySubnet `
    -AddressPrefix "192.168.1.0/24"
$vnet = New-AzureRmVirtualNetwork `
    -ResourceGroupName $rgName `
    -Location $location `
    -Name myVnet `
    -AddressPrefix "192.168.0.0/16" `
    -Subnet $subnetConfig

# Create a public IP address for the virtual machine
$pip = New-AzureRmPublicIpAddress `
    -ResourceGroupName $rgName `
    -Location $location `
    -AllocationMethod "Static" `
    -IdleTimeoutInMinutes "4" `
    -Name "mypublicdns$(Get-Random)"

# Create a Network Security Group and RDP rule
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig `
    -Name "myNetworkSecurityGroupRuleRDP" `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority "1000" `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange "3389" `
    -Access "Allow"
$nsg = New-AzureRmNetworkSecurityGroup `
    -ResourceGroupName $rgName `
    -Location $location `
    -Name "myNetworkSecurityGroup" `
    -SecurityRules $nsgRuleRDP

# Create a virtual network interface card
$nic = New-AzureRmNetworkInterface `
    -Name "myNic" `
    -ResourceGroupName $rgName `
    -Location $location `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $pip.Id `
    -NetworkSecurityGroupId $nsg.Id

# Prompt for admin credentials to add to new virtual machine
$cred = Get-Credential

# Create a virtual machine
$vmName = "myVM"
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_D1" | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName "myVM" -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName "MicrosoftWindowsServer" `
        -Offer "WindowsServer" -Skus "2016-Datacenter" -Version "latest" | `
    Add-AzureRmVMNetworkInterface -Id $nic.Id
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

# Define required information for our Key Vault and keys
$keyVault = Get-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $rgName;
$diskEncryptionKeyVaultUrl = $keyVault.VaultUri;
$keyVaultResourceId = $keyVault.ResourceId;
$keyEncryptionKeyUrl = (Get-AzureKeyVaultKey -VaultName $keyVaultName -Name "myKey").Key.kid;

# Encrypt our virtual machine
Set-AzureRmVMDiskEncryptionExtension `
    -ResourceGroupName $rgName `
    -VMName $vmName `
    -AadClientID $app.ApplicationId `
    -AadClientSecret $securePassword `
    -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
    -DiskEncryptionKeyVaultId $keyVaultResourceId `
    -KeyEncryptionKeyUrl $keyEncryptionKeyUrl `
    -KeyEncryptionKeyVaultId $keyVaultResourceId

# View encryption status
Get-AzureRmVmDiskEncryptionStatus  -ResourceGroupName $rgName -VMName $vmName