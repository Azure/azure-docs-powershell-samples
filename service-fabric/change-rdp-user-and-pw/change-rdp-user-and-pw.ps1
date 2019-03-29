Login-AzAccount
Get-AzSubscription
Set-AzContext -SubscriptionId 'yourSubscriptionID'

$nodeTypeName = 'nt1vm'
$resourceGroup = 'sfclustertutorialgroup'
$publicConfig = @{'UserName' = 'newuser'}
$privateConfig = @{'Password' = 'PasSwo0rd$#!'}
$extName = 'VMAccessAgent'
$publisher = 'Microsoft.Compute'
$node = Get-AzVmss -ResourceGroupName $resourceGroup -VMScaleSetName $nodeTypeName
$node = Add-AzVmssExtension -VirtualMachineScaleSet $node -Name $extName -Publisher $publisher -Setting $publicConfig -ProtectedSetting $privateConfig -Type $extName -TypeHandlerVersion '2.0' -AutoUpgradeMinorVersion $true

Update-AzVmss -ResourceGroupName $resourceGroup -Name $nodeTypeName -VirtualMachineScaleSet $node
