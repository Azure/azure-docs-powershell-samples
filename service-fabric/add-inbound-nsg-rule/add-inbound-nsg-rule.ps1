Login-AzAccount
Get-AzSubscription
Set-AzContext -SubscriptionId "yourSubscriptionID"

$RGname="sfclustertutorialgroup"
$port=8081
$rulename="allowAppPort$port"
$nsgname="sf-vnet-security"

# Get the NSG resource
$resource = Get-AzResource | Where {$_.ResourceGroupName –eq $RGname -and $_.ResourceType -eq "Microsoft.Network/networkSecurityGroups"} 
$nsg = Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname

# Add the inbound security rule.
$nsg | Add-AzNetworkSecurityRuleConfig -Name $rulename -Description "Allow app port" -Access Allow `
    -Protocol * -Direction Inbound -Priority 3891 -SourceAddressPrefix "*" -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange $port

# Update the NSG.
$nsg | Set-AzNetworkSecurityGroup
