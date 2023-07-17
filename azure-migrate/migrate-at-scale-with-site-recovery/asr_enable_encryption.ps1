Param(
    [parameter(Mandatory=$true)]
    $CsvFilePath
)

$ErrorActionPreference = "Stop"

$scriptsPath = $PSScriptRoot
if ($PSScriptRoot -eq "") {
    $scriptsPath = "."
}

$datestr = (Get-Date).tostring("yyyyMMdd_HHmmss")
$LogFilePath = "log.asr_enable_encryption.ps1.$datestr.txt"

Start-Transcript -Path $LogFilePath
$vms = Import-Csv -Path $CsvFilePath

# Enable encryption at host and CMK

foreach ($csvvm in $vms){
    # Stop Azure Virtual Machine
    $vm = Get-AzVM -ResourceGroupName $csvvm.TARGET_RESOURCE_GROUP -Name $csvvm.TARGET_MACHINE_NAME
    Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.name -Force
    # Enable Host Encryption
    Update-AzVM -VM $vm -ResourceGroupName $vm.ResourceGroupName -EncryptionAtHost $true
    # Get Disk Encryption Set Object
    $diskEncryptionSet = Get-AzDiskEncryptionSet -ResourceGroupName $vm.ResourceGroupName -Name $csvvm.ENCRYPTION_SET_NAME
    foreach ($disk in $vm.storageProfile.OSDisk) {
        Write-Host "Get OS Disks"
        $osdisk = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $disk.name
        Write-Host $osdisk.Name -ForegroundColor Green
        # Update disk with the new configuration: enable CMK encryption and disable public network access
        New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id -PublicNetworkAccess Disabled -NetworkAccessPolicy DenyAll | Update-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $osdisk.name     
    }
    foreach ($disk in $vm.storageProfile.DataDisks) {
        Write-Host "Get Data Disks"
        $datadisk = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $disk.name
        Write-Host $datadisk.Name -ForegroundColor Green
        New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id -PublicNetworkAccess Disabled -NetworkAccessPolicy DenyAll | Update-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $datadisk.name     
    }
    # Start Azure Virtual Machine
    Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.name
}

Stop-Transcript