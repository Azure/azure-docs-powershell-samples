# You will need an existing Managed Instance as a prerequisite for completing this script.
# See https://docs.microsoft.com/en-us/azure/sql-database/scripts/sql-database-create-configure-managed-instance-powershell

# Log in to your Azure account:
Connect-AzAccount

# If there are multiple subscriptions, choose the one where AKV is created: 
Set-AzContext -SubscriptionId "subscription ID"

# Install the preview version of Az.Sql PowerShell package 1.1.1-preview if you are running this PowerShell locally (uncomment below):
# Install-Module -Name Az.Sql -RequiredVersion 1.1.1-preview -AllowPrerelease -Force

# 1. Create Resource and setup Azure Key Vault (skip if already done)

# Create Resource group (name the resource and specify the location)
$location = "westus2" # specify the location
$resourcegroup = "MyRG" # specify a new RG name
New-AzResourceGroup -Name $resourcegroup -Location $location

# Create new Azure Key Vault with a globally unique VaultName and soft-delete option turned on:
$vaultname = "MyKeyVault" # specify a globally unique VaultName
New-AzKeyVault -VaultName $vaultname -ResourceGroupName $resourcegroup -Location $location -EnableSoftDelete

# Authorize Managed Instance to use the AKV (wrap/unwrap key and get public part of key, if public part exists): 
$objectid = (Set-AzSqlInstance -ResourceGroupName $resourcegroup -Name "MyManagedInstance" -AssignIdentity).Identity.PrincipalId
Set-AzKeyVaultAccessPolicy -BypassObjectIdValidation -VaultName $vaultname -ObjectId $objectid -PermissionsToKeys get,wrapKey,unwrapKey

# Allow access from trusted Azure services: 
Update-AzKeyVaultNetworkRuleSet -VaultName $vaultname -Bypass AzureServices

# Turn the network rules ON by setting the default action to Deny: 
Update-AzKeyVaultNetworkRuleSet -VaultName $vaultname -DefaultAction Deny


# 2. Provide TDE Protector key (skip if already done)

# The recommended way is to import an existing key from a .pfx file. Replace "<PFX private key password>" with the actual password below:
$keypath = "c:\some_path\mytdekey.pfx" # Supply your .pfx path and name
$securepfxpwd = ConvertTo-SecureString -String "<PFX private key password>" -AsPlainText -Force 
$key = Add-AzKeyVaultKey -VaultName $vaultname -Name "MyTDEKey" -KeyFilePath $keypath -KeyFilePassword $securepfxpwd

# ...or get an existing key from the vault:
# $key = Get-AzKeyVaultKey -VaultName $vaultname -Name "MyTDEKey"

# Alternatively, generate a new key directly in Azure Key Vault (recommended for test purposes only - uncomment below):
# $key = Add-AzureKeyVaultKey -VaultName $vaultname -Name MyTDEKey -Destination Software -Size 2048

# 3. Set up BYOK TDE on Managed Instance:

# Assign the key to the Managed Instance:
# $key = 'https://contoso.vault.azure.net/keys/contosokey/01234567890123456789012345678901'
Add-AzSqlInstanceKeyVaultKey -KeyId $key.id -InstanceName "MyManagedInstance" -ResourceGroupName $resourcegroup

# Set TDE operation mode to BYOK: 
Set-AzSqlInstanceTransparentDataEncryptionProtector -Type AzureKeyVault -InstanceName "MyManagedInstance" -ResourceGroup $resourcegroup -KeyId $key.id