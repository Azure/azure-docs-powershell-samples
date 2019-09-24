# List and Get operations for Azure Cosmos Gremlin API

$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$databaseName = "database1"
$graphName = "graph1"
$accountResourceName = $accountName + "/gremlin/"
$databaseResourceName = $accountName + "/gremlin/" + $databaseName
$databaseResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases"
$graphResourceName = $accountName + "/gremlin/" + $databaseName + "/" + $graphName
$graphResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/graphs"

Read-Host -Prompt "List all databases in an account. Press Enter to continue"

Get-AzResource -ResourceType $databaseResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $accountResourceName  | Select-Object Properties

Read-Host -Prompt "Get a database in an account. Press Enter to continue"

Get-AzResource -ResourceType $databaseResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName | Select-Object Properties

Read-Host -Prompt "List all graphs in a database. Press Enter to continue"

Get-AzResource -ResourceType $graphResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName | Select-Object Properties

Read-Host -Prompt "Get a graph in a database. Press Enter to continue"

Get-AzResource -ResourceType $graphResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $graphResourceName | Select-Object Properties


