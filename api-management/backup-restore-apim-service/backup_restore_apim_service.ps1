##########################################################
#  Script to backup and restore api management service.
###########################################################

$random = (New-Guid).ToString().Substring(0,8)

# Azure specific details
$subscriptionId = "my-azure-subscription-id"
 
# Api Management service specific details
$apiManagementName = "apim-$random"
$resourceGroupName = "apim-rg-$random"
$location = "Japan East"
$organisation = "Contoso"
$adminEmail = "admin@contoso.com"
 
# Storage Account details
$storageAccountName = "backup$random"
$containerName = "backups"
$backupName = $apiManagementName + "-apimbackup"
 
# Select default azure subscription
Select-AzSubscription -SubscriptionId $subscriptionId
 
# Create a Resource Group 
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
 
# Create storage account    
New-AzStorageAccount -StorageAccountName $storageAccountName -Location $location -ResourceGroupName $resourceGroupName -Type Standard_LRS
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName)[0].Value
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey

# Create blob container
New-AzStorageContainer -Name $containerName -Context $storageContext -Permission blob
 
# Create API Management service
New-AzApiManagement -ResourceGroupName $resourceGroupName -Location $location -Name $apiManagementName -Organization $organisation -AdminEmail $adminEmail
 
# Backup API Management service.
Backup-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apiManagementName -StorageContext $storageContext -TargetContainerName $containerName -TargetBlobName $backupName
 
# Restore API Management service
Restore-AzApiManagement -ResourceGroupName $resourceGroupName -Name $apiManagementName -StorageContext $storageContext -SourceContainerName $containerName -SourceBlobName $backupName
