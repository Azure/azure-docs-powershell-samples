<#
.NAME
	create_sharedDisks.ps1

.DESCRIPTION
The script will scan a resource group for machines. It will then show a list of VMs available.
Once VMs are selected, the data disks will be offered,from each VM. From the selected disks, shared disks will be created to be later on attached to the cluster nodes.

.PERMISSIONS REQUIRED
    Contributor
.USE CASES

.Parameters
ResourceGroupName - resource group containing VM with cluster disks
clusterName - to be used as prefix for the shared disks
numberOfNodes - used to determined the minimum azure disk size and max shares for the disks
startingDiskNumber - initial number to be added to the shared disk names. 0 is Default
DiskNamePrefix - Prefix to be added to the disk name
.NOTES
    AUTHOR DATE: 2021-04-23
.CHANGE LOG
#>
param(
[Parameter(Mandatory=$true)]
[string]
$ResourceGroupName,
[Parameter(Mandatory=$true)]
[string]
$DiskNamePrefix,
[Parameter(Mandatory=$false)]
[int]
$NumberOfNodes=2,
[Parameter(Mandatory=$false)]
[int]
$startingDiskNumber=0,
[Parameter(Mandatory=$false)]
[switch]$linux)
switch ($numberOfNodes)
{
    {$numberOfNodes -gt 2}  {$minSize = 1024;$maxShares=5} #P30
    {$numberOfNodes -gt 5}  {$minSize = 8192;$maxShares=10} #P60
    default {$minSize = 256; $maxShares=2} #P15 - minimum size
}
if ($linux)
{
    "Linux mode requested. Importing ConsoleGuiTools..."
    Install-Module Microsoft.PowerShell.ConsoleGuiTools
    $VMs=get-azvm -ResourceGroupName $ResourceGroupName | Out-ConsoleGridView -OutputMode -Multiple -Title "Select VMs from resource group."
}
else {
    $VMs=get-azvm -ResourceGroupName $ResourceGroupName | Out-GridView -passthru -Title "Select VMs from resource group."
}
try
{
    $clusteredDiskPrefix="$diskNamePrefix-DataDisk-"
    Write-Output "Shared Disk prefix set to $clusteredDiskPrefix"
    $i=$startingDiskNumber
    foreach ($VM in $VMs)
    {
        if ($linux)
        {
            $datadisks=$VM.StorageProfile.DataDisks | Out-ConsoleGridView -OutputMode -Multiple  -Title "Select disks from $($VM.Name) to create shared disks."
        }
        else {
            $datadisks=$VM.StorageProfile.DataDisks | Out-GridView -passthru -Title "Select disks from $($VM.Name) to create shared disks."    
        }
        if ($datadisks)
        {
            $skuname="Premium_LRS"
            foreach ($diskname in $datadisks.name)
            {
                $disk=Get-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $diskname
                "Creating snapshot for disk $diskname"
                $snapshotConfig=New-AzSnapshotConfig -Location $VM.Location -CreateOption Copy -SourceResourceId $disk.Id -AccountType Standard_LRS
                $snapshot=New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName "$diskname-snapshot" -Snapshot $snapshotConfig
                $newdiskName="$clusteredDiskPrefix$i"
                Write-Output "New Disk name will be: $newdiskName . Size:$($snapshot.DiskSizeGB)"
                if ($snapshot.DiskSizeGB -lt $minSize)
                {
                    Write-Output "Disk is smaller than $minSize. Setting size to $minSizeGb to allow sharing."
                    $newdiskSizeGb=$minSize
                }
                else
                {
                    $newdiskSizeGb=$snapshot.DiskSizeGB
                }
                $newdiskconfig=New-AzDiskConfig -SkuName $skuname -Location $VM.Location -DiskSizeGB $newdiskSizeGb -MaxSharesCount $maxShares -CreateOption Copy -SourceResourceId $snapshot.Id
                $newdisk=New-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $newdiskName -Disk $newdiskconfig
                if ($newdisk) {
                    "Disk $($newdisk.Name) created."
                    "Removing Snapshots and detaching disks used to create cluster disks."
                    Remove-AzVMDataDisk -VM $VM -DataDiskNames $diskname | Update-AzVm
                    Remove-AzSnapshot -ResourceGroupName $snapshot.ResourceGroupName -SnapshotName $snapshot.Name -Force
                }
                $i++;
            } #foreach ($diskname in $datadisks.name)
        } # if ($datadisks)
    } #foreach ($VM in $VMs)
}
catch {
    Write-Error "Error creating shared disks. $Error."
}
