# Create resource group
New-AzResourceGroup -Name appDefinitionGroup -Location westcentralus

# Get Azure Active Directory group to manage the application
$groupid=(Get-AzADGroup -SearchString appManagers).Id

# Get role
$roleid=(Get-AzRoleDefinition -Name Owner).Id

# Create the definition for a managed application
New-AzManagedApplicationDefinition `
  -Name "ManagedStorage" `
  -Location "westcentralus" `
  -ResourceGroupName appDefinitionGroup `
  -LockLevel ReadOnly `
  -DisplayName "Managed Storage Account" `
  -Description "Managed Az.Storage Account" `
  -Authorization "${groupid}:$roleid" `
  -PackageFileUri "https://raw.githubusercontent.com/Azure/azure-managedapp-samples/master/samples/201-managed-storage-account/managedstorage.zip"
