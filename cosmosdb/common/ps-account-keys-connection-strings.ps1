# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# List an account's connection strings and keys; regenerate a key.
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$keyKind = "primary" # Other key kinds: secondary, primaryReadonly, secondaryReadonly
# --------------------------------------------------

Write-Host "List connection strings"
Get-AzCosmosDBAccountKey -ResourceGroupName $resourceGroupName `
    -Name $accountName -Type "ConnectionStrings"

Write-Host "List keys"
Get-AzCosmosDBAccountKey -ResourceGroupName $resourceGroupName `
    -Name $accountName -Type "Keys"

Write-Host "Reset key"
New-AzCosmosDBAccountKey  -ResourceGroupName $resourceGroupName `
    -Name $accountName -KeyKind $keyKind
