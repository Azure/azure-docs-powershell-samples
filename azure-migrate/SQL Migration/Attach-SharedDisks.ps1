<#
.NAME
	attach-SharedDisks.ps1

.DESCRIPTION
The script will scan a resource group for machines. It will then show a list of VMs available.
Once a VM (or more) is selected, the data disks will be offered. From the selected disks, shared disks will be attached to all the VMs.

.PERMISSIONS REQUIRED
    Contributor
.USE CASES

.Parameters
$ResourceGroupName - resource group containing VMs with cluster disks
$startingLunNumber - number to use as a starting LUN to attach disks. Default is 0 (assuming VM has no data disks).
$DisksResourceGroup - Resource group containing the disks to be attached
$linux - uses a linux compatible out-consolegridview to show the options.
.NOTES
    AUTHOR: Microsoft Services 
    AUTHOR DATE: 2020-Dec-16
.CHANGE LOG
#>
param(
[Parameter(Mandatory=$true)]
[string]
$ResourceGroupName,
[Parameter(Mandatory=$true)]
[string]
$DisksResourceGroup,
[Parameter(Mandatory=$false)]
[int]
$startingLunNumber=0,
[Parameter(Mandatory=$false)]
[switch]$linux)  
if ($linux)
{
    if (!(get-module Microsoft.PowerShell.ConsoleGuiTools))
    {
        Install-Module Microsoft.PowerShell.ConsoleGuiTools
        $VMs=get-azvm -ResourceGroupName $ResourceGroupName | Out-ConsoleGridView -OutputMode Multiple -Title "Select VM from resource group."
    }
}
else {
    $VMs=get-azvm -ResourceGroupName $ResourceGroupName | Out-GridView -passthru -Title "Select VMs from resource group."   
}
Write-Output "$($VMs.Count) VMs selected."
if ($VMs) 
{
    "Selecting Disks..."
    if ($DisksRG -eq "" -or $null -eq $DisksRG) {$DisksRG=$ResourceGroupName} #if no disks RG is specified, assumes same resource group for disks and VMs.
    "Looking for disks in $DisksRG RG."
    if ($linux)
    {
        if (!(get-module Microsoft.PowerShell.ConsoleGuiTools))
        {
            Install-Module Microsoft.PowerShell.ConsoleGuiTools
            $datadisks=Get-AzDisk -ResourceGroupName $DisksRG | Where-Object{$_.MaxShares -gt 0} | Select-Object Name, Id, MaxShares | Out-ConsoleGridView -OutputMode Multiple -Title "Select shared disks to be attached:"
        }
    }
    else {
        $datadisks=Get-AzDisk -ResourceGroupName $DisksRG | Where-Object{$_.MaxShares -gt 0} | Select-Object Name, Id,MaxShares | Out-GridView -PassThru -Title "Select shared disks to be attached:"
    }
    "$($datadisks.count) selected."
    try
    {
        if ($datadisks)
        {
            foreach ($VM in $VMs)
            {
                $i=$startingLunNumber
                "Working on $($VM.Name) VM. Disk LUNs starting at $i."
                foreach ($dd in $datadisks)
                {
                    #attach disk to VM
                    Add-AzVMDataDisk -VM $VM -Name $dd.Name -Lun $i -ManagedDiskId $dd.Id -CreateOption Attach
                    $i++;
                }
                Update-AzVm -VM $VM -ResourceGroupName $ResourceGroupName
            }
        }
    }
    catch {
        Write-Error "Error attaching new disks."
    }
}
