# Create resource group
New-AzureRmResourceGroup -Name appDefinitionGroup -Location westcentralus

# Get Azure Active Directory group to manage the application
$groupid=(Get-AzureRmADGroup -SearchString appManagers).Id

# Get role
$roleid=(Get-AzureRmRoleDefinition -Name Owner).Id

# Create the definition for a managed application
New-AzureRmManagedApplicationDefinition `
  -Name "ManagedStorage" `
  -Location "westcentralus" `
  -ResourceGroupName appDefinitionGroup `
  -LockLevel ReadOnly `
  -DisplayName "Managed Storage Account" `
  -Description "Managed Azure Storage Account" `
  -Authorization "${groupid}:$roleid" `
  -PackageFileUri "https://raw.githubusercontent.com/Azure/azure-managedapp-samples/master/samples/201-managed-storage-account/managedstorage.zip"
