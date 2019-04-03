# Log in to your Azure account:
Connect-AzAccount

# If there are multiple subscriptions, choose the one where AKV is created: 
Set-AzContext -SubscriptionId "subscription ID"

# Install the preview version of Az.Sql PowerShell package 1.1.1-preview if you are running this PowerShell locally (uncomment below):
# Install-Module -Name Az.Sql -RequiredVersion 1.1.1-preview -AllowPrerelease -Force

# 1. Create Resource and setup Azure Key Vault (skip if already done)

# Create Resource (name the resource and specify the location)
$location = "westus2" # specify the location
New-AzResourceGroup -Name "MyRG" -Location $location

# Create new Azure Key Vault with soft-delete option turned on (change name, RG and region): 
New-AzKeyVault -VaultName "MyKeyVault" -ResourceGroupName "MyRG" -Location $location -EnableSoftDelete

# Authorize Managed Instance to use the AKV (wrap/unwrap key and get public part of key, if public part exists): 
$objectid = (Get-AzResource -ResourceGroupName "MyRG" -Name "MyManagedInstance").Identity.PrincipalId
Set-AzKeyVaultAccessPolicy -BypassObjectIdValidation -VaultName "MyKeyVault" -ObjectId $objectid -PermissionsToKeys get,wrapKey,unwrapKey

# Allow access from trusted Azure services: 
Update-AzKeyVaultNetworkRuleSet -VaultName "MyKeyVault" -Bypass AzureServices

# Turn the network rules ON by setting the default action to Deny: 
Update-AzKeyVaultNetworkRuleSet -VaultName "MyKeyVault" -DefaultAction Deny


# 2. Provide TDE Protector key (skip if already done)

# Generate new key directly in Azure Key Vault (recommended for test purposes only - uncomment below):
# $key = Add-AzureKeyVaultKey -VaultName MyKeyVault -Name MyTDEKey -Destination Software -Size 2048

# Alternatively, the recommended way is to import an existing key from a .pfx file:
$securepfxpwd = ConvertTo-SecureString -String "MyPa$$w0rd" -AsPlainText -Force 
$key = Add-AzKeyVaultKey -VaultName "MyKeyVault" -Name "MyTDEKey" -KeyFilePath "c:\some_path\mytdekey.pfx" -KeyFilePassword $securepfxpwd

# ...or get an existing key from the vault:
# $key = Get-AzKeyVaultKey -VaultName "MyKeyVault" -Name "MyTDEKey"

# 3. Set up BYOK TDE on Managed Instance:

# Assign the key to the Managed Instance:
# $key = 'https://contoso.vault.azure.net/keys/contosokey/01234567890123456789012345678901'
Add-AzSqlInstanceKeyVaultKey -KeyId $key.id -InstanceName "MyManagedInstance" -ResourceGroupName "MyRG"

# Set TDE operation mode to BYOK: 
Set-AzSqlInstanceTransparentDataEncryptionProtector -Type AzureKeyVault -InstanceName "MyManagedInstance" -ResourceGroup "MyRG" -KeyId $key.id