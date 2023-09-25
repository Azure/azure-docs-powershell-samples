
<#

.DESCRIPTION

This sample demonstrates how to create a Managed Disk from a VHD file. 
Create Managed Disks from VHD files in following scenarios:
1. Create a Managed OS Disk from a specialized VHD file. A specialized VHD is a copy of VHD from an exisitng VM that maintains the user accounts, applications and other state data from your original VM. 
   Attach this Managed Disk as OS disk to create a new virtual machine.
2. Create a Managed data Disk from a VHD file. Attach the Managed Disk to an existing VM or attach it as data disk to create a new virtual machine.

.NOTES

1. Before you use this sample, please install the latest version of Azure PowerShell from here: http://go.microsoft.com/?linkid=9811175&clcid=0x409
2. Provide the appropriate values for each variable. Note: The angled brackets should not be included in the values you provide.


#>

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
$sku = 'Premium_LRS'

#Provide the Azure location (e.g. westus) where Managed Disk will be located. 
#The location should be same as the location of the storage account where VHD file is stored.
#Get all the Azure location using command below:
#Get-AzureRmLocation
$location = 'westus'

#Set the context to the subscription Id where Managed Disk will be created
Set-AzContext -Subscription $subscriptionId

#If you're creating an OS disk, add the following lines
#Acceptable values are either Windows or Linux
#$OSType = 'yourOSType'
#Acceptable values are either V1 or V2
#$HyperVGeneration = 'yourHyperVGen'

#If you're creating an OS disk, add -HyperVGeneration and -OSType parameters
$diskConfig = New-AzDiskConfig -SkuName $sku -Location $location -DiskSizeGB $diskSize -SourceUri $vhdUri -CreateOption Import

#Create Managed disk
New-AzDisk -DiskName $diskName -Disk $diskConfig -ResourceGroupName $resourceGroupName -StorageAccountId $storageAccountId
