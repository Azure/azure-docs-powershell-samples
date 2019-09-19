# Get RU for an Azure Cosmos Gremlin API database or graph
$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$databaseName = "database1"
$databaseThroughputResourceName = $accountName + "/gremlin/" + $databaseName + "/throughput"
$databaseThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/settings"
$graphName = "graph1"
$graphThroughputResourceName = $accountName + "/gremlin/" + $databaseName + "/" + $graphName + "/throughput"
$graphThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/graphs/settings"

# Get the throughput for a database (returns RU/s or error if not set)
Get-AzResource -ResourceType $databaseThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseThroughputResourceName  | Select-Object Properties

# Get the throughput for a graph (returns RU/s or error if not set)
Get-AzResource -ResourceType $graphThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $graphThroughputResourceName  | Select-Object Properties
