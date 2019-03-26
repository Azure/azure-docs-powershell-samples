Param(
    [parameter(Mandatory=$true)]
    $SubscriptionId,
    [parameter(Mandatory=$true)]
    $VaultName,
    [parameter(Mandatory=$true)]
    $ConfigurationServer,
    [parameter(Mandatory=$true)]
    $CsvOutput
)

class ProtectableItemInfo
{
    [string]$Machine
    [string]$ProtectionStatus
}

$currentContext = Get-AzContext
$currentSubscription = $currentContext.Subscription
if ($currentSubscription.Id -ne $subscriptionId)
{
    Set-AzContext -Subscription $subscriptionId
    $currentContext = Get-AzContext
    $currentSubscription = $currentContext.Subscription
    if ($currentSubscription.Id -ne $subscriptionId)
    {
        LogErrorAndThrow("SubscriptionId '$($subscriptionId)' is not selected as current default subscription")
    }
}

$targetVault = Get-AzRecoveryServicesVault -Name $VaultName
if ($targetVault -eq $null)
{
    LogError("Vault with name '$($vaultName)' unable to find")
}

Set-AzRecoveryServicesAsrVaultContext -Vault $targetVault
$fabricServer = Get-AzRecoveryServicesAsrFabric `
    -FriendlyName $ConfigurationServer
$protectionContainer = Get-AzRecoveryServicesAsrProtectionContainer `
    -Fabric $fabricServer
    
$items = Get-AzRecoveryServicesAsrProtectableItem `
    -ProtectionContainer $protectionContainer

$protectedItemStatusArray = New-Object System.Collections.Generic.List[System.Object]
if ($items.Count -gt 0)
{
    foreach ($item in $items)
    {
        $statusItemInfo = [ProtectableItemInfo]::new()
        $statusItemInfo.Machine = $item.FriendlyName
        $statusItemInfo.ProtectionStatus = $item.ProtectionStatus
    
        $protectedItemStatusArray.Add($statusItemInfo)
    }
    
    $protectedItemStatusArray.ToArray() | Export-Csv $CsvOutput -Delimiter ',' -NoTypeInformation
    Write-Host "Information written in csv file '$($CsvOutput)'"    
} else {
    Write-Host "There are no items in this container"    
}




