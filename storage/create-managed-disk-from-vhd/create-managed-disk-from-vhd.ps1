#Provide the subscription Id
$subscriptionId = 'yourSubscriptionId'

#Provide the name of your resource group
$resourceGroupName ='yourResourceGroupName'

#Provide the name of the Managed Disk
$diskName = 'yourDiskName'

#Provide the size of the disks in GB. It should be greater than the VHD file size.
$diskSize = '128'

#Provide the URI of the VHD file that will be used to create Managed Disk. 
# VHD file can be deleted as soon as Managed Disk is created.
# e.g. https://contosostorageaccount1.blob.core.windows.net/vhds/contoso-um-vm120170302230408.vhd 
$vhdUri = 'https://contosoststorageaccount1.blob.core.windows.net/vhds/contosovhd123.vhd' 

#Provide the storage type for the Managed Disk. PremiumLRS or StandardLRS.
$accountType = 'PremiumLRS'

#Provide the Azure location (e.g. westus) where Managed Disk will be located. 
#The location should be same as the location of the storage account where VHD file is stored.
#Get all the Azure location using command below:
#Get-AzureRmLocation
$location = 'westus'

#Set the context to the subscription Id where Managed Disk will be created
Select-AzureRmSubscription -SubscriptionId $SubscriptionId

$diskConfig = New-AzureRmDiskConfig -AccountType $accountType  -Location $location -DiskSizeGB $diskSize -SourceUri $vhdUri -CreateOption Import

#Create Managed disk
New-AzureRmDisk -DiskName $diskName -Disk $diskConfig -ResourceGroupName $resourceGroupName







