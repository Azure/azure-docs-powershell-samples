# Get RU for an Azure Cosmos Gremlin API database or graph
$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$databaseThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/settings"
$graphThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/graphs/settings"
$accountName = "mycosmosaccount"
$databaseName = "database1"
$graphName = "graph1"
$databaseThroughputResourceName = $accountName + "/gremlin/" + $databaseName + "/throughput"
$graphThroughputResourceName = $accountName + "/gremlin/" + $databaseName + "/" + $graphName + "/throughput"

# Get the throughput for a database (returns RU/s or 404 "Not found" error if not set)
Get-AzResource -ResourceType $databaseThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseThroughputResourceName  | Select-Object Properties

# Get the throughput for a graph (returns RU/s or 404 "Not found" error if not set)
Get-AzResource -ResourceType $graphThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $graphThroughputResourceName  | Select-Object Properties
