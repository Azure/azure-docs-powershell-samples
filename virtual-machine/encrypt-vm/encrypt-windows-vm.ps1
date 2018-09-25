# Edit these global variables with you unique Key Vault name, resource group name and location
#Name of the Key Vault
$keyVaultName = "myKeyVault00"
#Resource Group Name
$rgName = "myResourceGroup"
#Region
$location = "East US"
#Password to place w/in the KeyVault
$securePassword = ConvertTo-SecureString -String "P@ssword!" -AsPlainText -Force
#Name for the Azure AD Application
$appName = "My App"
#Name for the VM to be encrypt
$vmName = "myEncryptedVM"
#user name for the admin account in the vm being created and then encrypted
$vmAdminName = "encryptedUser"

# Register the Key Vault provider and create a resource group
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

# Put the password in the Key Vault as a Key Vault Secret so we can use it later
# We should never put passwords in scripts.
Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name adminCreds -SecretValue $securePassword
Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name protectValue -SecretValue $password


# Create Azure Active Directory app and service principal
$app = New-AzureRmADApplication -DisplayName $appName `
    -HomePage "https://myapp0.contoso.com" `
    -IdentifierUris "https://contoso.com/myapp0" `
    -Password (Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name adminCreds).SecretValue

New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId

# Set permissions to allow your AAD service principal to read keys from Key Vault
Set-AzureRmKeyVaultAccessPolicy -VaultName $keyvaultName `
    -ServicePrincipalName $app.ApplicationId  `
    -PermissionsToKeys decrypt,encrypt,unwrapKey,wrapKey,verify,sign,get,list,update `
    -PermissionsToSecrets get,list,set,delete,backup,restore,recover,purge

# Create PSCredential object for VM
$cred = New-Object System.Management.Automation.PSCredential($vmAdminName, (Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name adminCreds).SecretValue)

# Create a virtual machine
New-AzureRmVM `
  -ResourceGroupName $rgName `
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
    -AadClientSecret (Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name adminCreds).SecretValueText `
    -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
    -DiskEncryptionKeyVaultId $keyVaultResourceId `
    -KeyEncryptionKeyUrl $keyEncryptionKeyUrl `
    -KeyEncryptionKeyVaultId $keyVaultResourceId

# View encryption status
Get-AzureRmVmDiskEncryptionStatus  -ResourceGroupName $rgName -VMName $vmName

<#
#clean up
Remove-AzureRmResourceGroup -Name $rgName
#removes all of the Azure AD Applications you created w/ the same name
Remove-AzureRmADApplication -ObjectId $app.ObjectId -Force
#>
