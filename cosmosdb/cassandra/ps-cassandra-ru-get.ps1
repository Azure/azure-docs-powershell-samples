# Get RU for an Azure Cosmos Cassandra API keyspace or table
$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$keyspaceName = "keyspace1"
$tableName = "table1"
$keyspaceThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/settings"
$tableThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/tables/settings"
$keyspaceThroughputResourceName = $accountName + "/cassandra/" + $keyspaceName + "/throughput"
$tableThroughputResourceName = $accountName + "/cassandra/" + $keyspaceName + "/" + $tableName + "/throughput"

# Get the throughput for a keyspace (returns RU/s or 404 "Not found" error if not set)
Get-AzResource -ResourceType $keyspaceThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $keyspaceThroughputResourceName | Select-Object Properties

if($error[0].Exception.Message.Split(",")[0].Split(":")[1].Replace("`"","") -eq "NotFound")
{
    Write-Host "Throughput not set on keyspace resource"
    $error.Clear()
}

# Get the throughput for a table (returns RU/s or 404 "Not found" error if not set)
Get-AzResource -ResourceType $tableThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $tableThroughputResourceName | Select-Object Properties
