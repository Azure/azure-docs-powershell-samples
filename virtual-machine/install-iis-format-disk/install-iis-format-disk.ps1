# This script is intended to be run from a custom script extension on a VM with an added data disk.
# Install IIS on the VM
Add-WindowsFeature Web-Server
# Format the data disk that has been added to the VM
Get-Disk | Where partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "myDataDisk" -Confirm:$false
