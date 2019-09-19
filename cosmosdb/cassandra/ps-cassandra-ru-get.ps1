# Get RU for an Azure Cosmos Cassandra API keyspace or table
$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$keyspaceName = "keyspace1"
$tableName = "table1"
$keyspaceThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/settings"
$keyspaceThroughputResourceName = $accountName + "/cassandra/" + $keyspaceName + "/throughput"
$tableThroughputResourceName = $accountName + "/cassandra/" + $keyspaceName + "/" + $tableName + "/throughput"
$tableThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/tables/settings"

# Get the throughput for a keyspace (returns RU/s or error)
Get-AzResource -ResourceType $keyspaceThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $keyspaceThroughputResourceName | Select-Object Properties

# Get the throughput for a table (returns RU/s or error)
Get-AzResource -ResourceType $tableThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $tableThroughputResourceName | Select-Object Properties
