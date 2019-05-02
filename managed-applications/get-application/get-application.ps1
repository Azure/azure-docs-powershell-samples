# Get managed applications from known resource group
Get-AzManagedApplication -ResourceGroupName "DemoApp"

# Get ID of managed resource group
(Get-AzManagedApplication -ResourceGroupName "DemoApp").Properties.managedResourceGroupId

# Get virtual machines in the managed resource group
Get-AzResource -ResourceGroupName DemoApp6zkevchqk7sfq -ResourceType Microsoft.Compute/virtualMachines

# Get information about virtual machines in managed resource group
Get-AzVM -ResourceGroupName DemoApp6zkevchqk7sfq | ForEach{ $_.Name, $_.storageProfile.osDisk.osType, $_.hardwareProfile.vmSize }

## Resize virtual machines in managed resource group
$vm = Get-AzVM -ResourceGroupName DemoApp6zkevchqk7sfq -VMName demoVM
$vm.HardwareProfile.VmSize = "Standard_D2_v2"
Update-AzVM -VM $vm -ResourceGroupName DemoApp6zkevchqk7sfq
