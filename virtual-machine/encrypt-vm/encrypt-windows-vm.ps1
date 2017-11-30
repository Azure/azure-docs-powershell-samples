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

# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a virtual machine
New-AzureRmVM `
  -ResourceGroupName $resourceGroup `
  -Name $vmName `
  -Location $location `
  -ImageName "Win2016Datacenter" `
  -VirtualNetworkName "myVnet" `
  -SubnetName "mySubnet" `
  -SecurityGroupName "myNetworkSecurityGroup" `
  -PublicIpAddressName "myPublicIp" `
  -Credential $cred `
  -OpenPorts 3389

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