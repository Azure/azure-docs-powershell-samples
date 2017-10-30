##########################################################
#  Script to backup and restore api management service.
###########################################################

$random = (New-Guid).ToString().Substring(0,8)

#Azure specific details
$subscriptionId = "my-azure-subscription-id"

# Api Management service specific details
$apimServiceName = "apim-$random"
$resourceGroupName = "apim-rg-$random"
$location = "Japan East"
$organisation = "Contoso"
$adminEmail = "admin@contoso.com"

# Storage Account details
$storageAccountName = backup_$random
$containerName = "backups"
$backupName = $apimServiceName + ".apimbackup"

# Select into the ResourceGroup
Select-AzureRmSubscription -SubscriptionId $subscriptionId

# Create a Resource Group 
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -Force

# Create storage account    
New-AzureRmStorageAccount -StorageAccountName $storageAccountName -Location $location -ResourceGroupName $resourceGroupName -Type Standard_LRS
$storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName)[0].Value
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey

# Create API Management service
New-AzureRmApiManagement -ResourceGroupName $resourceGroupName -Location $location -Name $apiManagementName -Organization $organisation -AdminEmail $adminEmail

# Backup API Management service.
Backup-AzureRmApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -StorageContext $storageContext -TargetContainerName $containerName -TargetBlobName $backupName

# Restore API Management service
Restore-AzureRmApiManagement -ResourceGroupName $resourceGroupName -Name $apimServiceName -StorageContext $storageContext -SourceContainerName $containerName -SourceBlobName $backupName


