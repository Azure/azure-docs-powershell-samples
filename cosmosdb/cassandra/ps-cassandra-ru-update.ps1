# Update RU for an Azure Cosmos Cassandra API keyspace or table

$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$keyspaceName = "keyspace1"
$tableName = "table1"
$keyspaceThroughputResourceName = $accountName + "/cassandra/" + $keyspaceName + "/throughput"
$keyspaceThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/settings"
$tableThroughputResourceName = $accountName + "/cassandra/" + $keyspaceName + "/" + $tableName + "/throughput"
$tableThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/tables/settings"
$throughput = 500
$updateResource = "keyspace" # or "table"

$properties = @{
    "resource"=@{"throughput"=$throughput}
}

if($updateResource -eq "keyspace"){
    Set-AzResource -ResourceType $keyspaceThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $keyspaceThroughputResourceName -PropertyObject $properties
}
elseif($updateResource -eq "table"){
Set-AzResource -ResourceType $tableThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $tableThroughputResourceName -PropertyObject $tableProperties
}
else {
    Write-Host("Must select keyspace or table")    
}
