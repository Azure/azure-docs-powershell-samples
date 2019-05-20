# Account keys and connection string operations for Azure Cosmos account

$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$keyKind = @{ "keyKind"="Primary" }


Read-Host -Prompt "List connection strings for an Azure Cosmos Account"

Invoke-AzResourceAction -Action listConnectionStrings `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName -Name $accountName | Select-Object *

Read-Host -Prompt "List keys for an Azure Cosmos Account"

Invoke-AzResourceAction -Action listKeys `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName -Name $accountName | Select-Object *

Read-Host -Prompt "Regenerate the primary key for an Azure Cosmos Account"

$keys = Invoke-AzResourceAction -Action regenerateKey `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName -Name $accountName -Parameters $keyKind

Write-Host $keys
