Login-AzureRmAccount
Get-AzureRmSubscription
Set-AzureRmContext -SubscriptionId 'yourSubscriptionID'

$nodeTypeName = 'nt1vm'
$resourceGroup = 'sfclustertutorialgroup'
$publicConfig = @{'UserName' = 'newuser'}
$privateConfig = @{'Password' = 'PasSwo0rd$#!'}
$extName = 'VMAccessAgent'
$publisher = 'Microsoft.Compute'
$node = Get-AzureRmVmss -ResourceGroupName $resourceGroup -VMScaleSetName $nodeTypeName
$node = Add-AzureRmVmssExtension -VirtualMachineScaleSet $node -Name $extName -Publisher $publisher -Setting $publicConfig -ProtectedSetting $privateConfig -Type $extName -TypeHandlerVersion '2.0' -AutoUpgradeMinorVersion $true

Update-AzureRmVmss -ResourceGroupName $resourceGroup -Name $nodeTypeName -VirtualMachineScaleSet $node