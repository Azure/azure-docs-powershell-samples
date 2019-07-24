# List and Get operations for Azure Cosmos MongoDB API
$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount" # must be lower case.
$databaseName = "database1"
$collectionName = "collection1"
$accountResourceName = $accountName + "/mongodb/"
$databaseResourceName = $accountName + "/mongodb/" + $databaseName
$databaseResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases"
$collectionResourceName = $accountName + "/mongodb/" + $databaseName + "/" + $collectionName
$collectionResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/collections"

Read-Host -Prompt "List all databases in an account. Press Enter to continue"

Get-AzResource -ResourceType $databaseResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $accountResourceName  | Select-Object Properties

Read-Host -Prompt "Get a database in an account. Press Enter to continue"

Get-AzResource -ResourceType $databaseResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName | Select-Object Properties

Read-Host -Prompt "List all collections in a database. Press Enter to continue"

Get-AzResource -ResourceType $collectionResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName | Select-Object Properties

Read-Host -Prompt "Get a collection in a database. Press Enter to continue"

Get-AzResource -ResourceType $collectionResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $collectionResourceName | Select-Object Properties
