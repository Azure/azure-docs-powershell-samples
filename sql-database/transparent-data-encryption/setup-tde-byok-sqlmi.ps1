# Log in to your Azure account:
Connect-AzAccount

# If there are multiple subscriptions, choose the one where AKV is created: 
Set-AzContext -SubscriptionId "subscription ID"

# Install the preview version of AzureRM.Sql PowerShell package 4.11.6-preview if you are running this PowerShell locally (uncomment below):
# Install-Module -Name AzureRM.Sql -RequiredVersion 4.11.6-preview -AllowPrerelease

# 1. Create Resource and setup Azure Key Vault (skip if already done)

# Create Resource (name the resource and specify the location)
$location = "westus2" # specify the location
New-AzResourceGroup -Name "MyRG" -Location $location

# Create new Azure Key Vault with soft-delete option turned on (change name, RG and region): 
New-AzKeyVault -VaultName "MyKeyVault" -ResourceGroupName "MyRG" -Location $location -EnableSoftDelete

# Create Managed Service Identity for the Managed Instance: 
$instance = Set-AzSqlManagedInstance -ResourceGroupName "MyRG" -Name "MyManagedInstance" -AssignIdentity

# Authorize Managed Instance to use the AKV (wrap/unwrap key and get public part of key, if public part exists): 
Set-AzKeyVaultAccessPolicy -VaultName "MyKeyVault" -ServicePrincipalName $instance.Identity -PermissionsToKeys get,wrapKey,unwrapKey

# Allow access from trusted Azure services: 
Update-AzKeyVaultNetworkRuleSet -VaultName "MyKeyVault" -Bypass AzureServices

# Turn the network rules ON by setting the default action to Deny: 
Update-AzKeyVaultNetworkRuleSet -VaultName "MyKeyVault" -DefaultAction Deny


# 2. Provide TDE Protector key (skip if already done)

# Generate new key directly in Azure Key Vault (recommended for test purposes only - uncomment below):
# $key = Add-AzureKeyVaultKey -VaultName MyKeyVault -Name MyTDEKey -Destination Software -Size 2048

# Alternatively, the recommended way is to import an existing key from a .pfx file:
$securepfxpwd = ConvertTo-SecureString -String 'MyPa$$w0rd' -AsPlainText -Force 
$key = Add-AzureKeyVaultKey -VaultName 'MyKeyVault' -Name 'MyTDEKey' -KeyFilePath 'c:\some_path\mytdekey.pfx' -KeyFilePassword $securepfxpwd


# 3. Set up BYOK TDE on Managed Instance:

# Assign the key to the Managed Instance:
# $key = 'https://contoso.vault.azure.net/keys/contosokey/01234567890123456789012345678901'
Add-AzSqlManagedInstanceKeyVaultKey -KeyId $key -ManagedInstanceName "MyManagedInstance" -ResourceGroupName "MyRG"

# Set TDE operation mode to BYOK: 
Set-AzSqlManagedInstanceTransparentDataEncryptionProtector -Type AzureKeyVault -ManagedInstanceName "MyManagedInstance" -ResourceGroup "MyRG"
