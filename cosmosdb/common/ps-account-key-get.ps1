# List keys for an Azure Cosmos Account
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"

Invoke-AzResourceAction -Action listKeys `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName -Name $accountName | Select-Object *