# List and Get operations for Azure Cosmos MongoDB API
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount" # must be lower case.
$databaseName = "database1"
$collectionName = "collection1"
$accountResourceName = $accountName + "/mongodb/"
$databaseResourceName = $accountName + "/mongodb/" + $databaseName
$collectionResourceName = $accountName + "/mongodb/" + $databaseName + "/" + $collectionName

Read-Host -Prompt "List all databases in an account. Press Enter to continue"

Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $accountResourceName  | Select-Object Properties

Read-Host -Prompt "Get a database in an account. Press Enter to continue"

Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName | Select-Object Properties

Read-Host -Prompt "List all collections in a database. Press Enter to continue"

Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases/collections" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName | Select-Object Properties

Read-Host -Prompt "Get a collection in a database. Press Enter to continue"

Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases/collections" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $collectionResourceName | Select-Object Properties
