Login-AzureRmAccount
Get-AzureRmSubscription
Set-AzureRmContext -SubscriptionId "yourSubscriptionID"

$RGname="sfclustertutorialgroup"
$port=8081
$rulename="allowAppPort$port"
$nsgname="sf-vnet-security"

# Get the NSG resource
$resource = Get-AzureRmResource | Where {$_.ResourceGroupName –eq $RGname -and $_.ResourceType -eq "Microsoft.Network/networkSecurityGroups"} 
$nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname

# Add the inbound security rule.
$nsg | Add-AzureRmNetworkSecurityRuleConfig -Name $rulename -Description "Allow app port" -Access Allow `
    -Protocol * -Direction Inbound -Priority 3891 -SourceAddressPrefix "*" -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange $port

# Update the NSG.
$nsg | Set-AzureRmNetworkSecurityGroup