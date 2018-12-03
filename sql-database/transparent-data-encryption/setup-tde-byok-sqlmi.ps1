# Log in to your Azure account:
Connect-AzureRmAccount

# If there are multiple subscriptions, choose the one where AKV is created: 
Set-AzureRmContext -SubscriptionId <subscription ID>

# 1. Create and setup Azure Key Vault (skip if already done)

# Create new Azure Key Vault with soft-delete option turned on (change name, RG and region): 
New-AzureRmKeyVault -VaultName "MyKeyVault" -ResourceGroupName "MyRG" -Location "My Region" -EnableSoftDelete

# Create Managed Service Identity for the Managed Instance: 
$instance = Set-AzureRmSqlManagedInstance -ResourceGroupName "MyRG" -Name "MyManagedInstance" -AssignIdentity

# Authorize Managed Instance to use the AKV (wrap/unwrap key and get public part of key, if public part exists): 
Set-AzureRmKeyVaultAccessPolicy -VaultName "MyKeyVault" -ServicePrincipalName $instance.Identity -PermissionsToKeys get,wrapKey,unwrapKey

# Allow access from trusted Azure services: 
Update-AzureRmKeyVaultNetworkRuleSet -VaultName "MyKeyVault" -Bypass AzureServices

# Turn the network rules ON by setting the default action to Deny: 
Update-AzureRmKeyVaultNetworkRuleSet -VaultName "MyKeyVault" -DefaultAction Deny


# 2. Provide TDE Protector key (skip if already done)

# Generate new key directly in Azure Key Vault (recommended for test purposes only):
$key = Add-AzureKeyVaultKey -VaultName MyKeyVault -Name MyTDEKey -Destination Software -Size 2048

# Alternatively, import existing key from .pfx file:
$securepfxpwd = ConvertTo-SecureString –String 'MyPa$$w0rd' –AsPlainText –Force 
$key = Add-AzureKeyVaultKey -VaultName 'MyKeyVault' -Name 'MyTDEKey' -KeyFilePath 'c:\some_path\mytdekey.pfx' -KeyFilePassword $securepfxpwd


# 3. Set up BYOK TDE on Managed Instance:

# Assign the key to the Managed Instance:
# $key = 'https://contoso.vault.azure.net/keys/contosokey/01234567890123456789012345678901'
Add-AzureRmSqlManagedInstanceKeyVaultKey -KeyId $key -Name MyManagedInstance -ResourceGroupName MyRG

# Set TDE operation mode to BYOK: 
Set-AzureRmSqlManagedInstanceTransparentDataEncryptionProtector -Type AzureKeyVault -Name "MyManagedInstance" -ResourceGroup "MyRG"