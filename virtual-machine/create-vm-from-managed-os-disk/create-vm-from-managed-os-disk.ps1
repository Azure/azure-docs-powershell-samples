#Provide the subscription Id
$subscriptionId = 'yourSubscriptionId'

#Provide the name of your resource group
$resourceGroupName ='yourResourceGroupName'

#Provide the name of the Managed Disk
$diskName = 'yourDiskName'

#Provide the Azure region (e.g. westus) where virtual machine will be located.
#This location should be same as the Managed Disk location 
#Get all the Azure location using command below:
#Get-AzureRmLocation
$location = 'westus'

#Provide the name of an existing virtual network where virtual machine will be created
$virtualNetworkName = 'yourVirtualNetworkName'

#Provide the name of the virtual machine
$virtualMachineName = 'yourVirtualMachineName'

#Provide the size of the virtual machine
#e.g. Standard_DS3
#Get all the vm sizes in a region using below script:
#e.g. Get-AzureRmVMSize -Location westus
$virtualMachineSize = 'Standard_DS3'

#Set the context to the subscription Id where Managed Disk will be created
Select-AzureRmSubscription -SubscriptionId $SubscriptionId

#Get the Managed Disk based on the resource group and the disk name
$disk =  Get-AzureRmDisk -ResourceGroupName $resourceGroupName -DiskName $diskName

#Initialize virtual machine configuration
$VirtualMachine = New-AzureRmVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize

#Use the Managed Disk Resource Id to attach it to the virtual machine. Please change the OS type to linux if OS disk has linux OS
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -ManagedDiskId $disk.Id -CreateOption Attach -Windows

#Create a public IP for the VM  
$publicIp = New-AzureRmPublicIpAddress -Name ($VirtualMachineName.ToLower()+'_ip') -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic

#Get the virtual network where virtual machine will be hosted
$vnet = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName

# Create NIC in the first subnet of the virtual network 
$nic = New-AzureRmNetworkInterface -Name ($VirtualMachineName.ToLower()+'_nic') -ResourceGroupName $resourceGroupName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id

$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

#Create the virtual machine with Managed Disk
New-AzureRmVM -VM $VirtualMachine -ResourceGroupName $resourceGroupName -Location $location