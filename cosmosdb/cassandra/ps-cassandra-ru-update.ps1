# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update database or container throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "cosmos" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$keyspaceName = "ks1" # Database without shared throughput
$tableName = "t1" # Database with shared throughput
$newRUsKeyspace = 800
$newRUsTable = 600

# Schema columns to create schema instance
# When Get-AzCosmosDBCassandraTable output.Resource.Schema works,
# can remove the following and retrieve existing schema programmatically
$partitionKeys = @("machine", "cpu", "mtime")
$clusterKeys = @( 
    @{ name = "loadid"; orderBy = "Asc" };
    @{ name = "duration"; orderBy = "Desc" }
)
$columns = @(
    @{ name = "loadid"; type = "uuid" };
    @{ name = "machine"; type = "uuid" };
    @{ name = "cpu"; type = "int" };
    @{ name = "mtime"; type = "int" };
    @{ name = "load"; type = "float" };
    @{ name = "duration"; type = "float" }
)
# --------------------------------------------------

Write-Host "Updating keyspace throughput"
Set-AzCosmosDBCassandraKeyspace -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $keyspaceName `
    -Throughput $newRUsKeyspace

# Retrieve table to get current schema
# This does not work at the time of this writing
# For comparison, run Azure CLI command:
# az cosmosdb cassandra table show -g myResourceGroup -a myaccount -k myKeyspace -n myTable

# $table = Get-AzCosmosDBCassandraTable -ResourceGroupName $resourceGroupName `
#     -AccountName $accountName -KeyspaceName $keyspaceName `
#     -Name $tableName
# $schema = $table.Resource.Schema
# $schema


# Table Schema
$psClusterKeys = @()
ForEach ($clusterKey in $clusterKeys) {
    $psClusterKeys += New-AzCosmosDBCassandraClusterKey -Name $clusterKey.name -OrderBy $clusterKey.orderBy
}

$psColumns = @()
ForEach ($column in $columns) {
    $psColumns += New-AzCosmosDBCassandraColumn -Name $column.name -Type $column.type
}

$schema = New-AzCosmosDBCassandraSchema `
    -PartitionKey $partitionKeys `
    -ClusterKey $psClusterKeys `
    -Column $psColumns

Write-Host "Updating table throughput"
Set-AzCosmosDBCassandraTable -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -KeyspaceName $keyspaceName `
    -Name $tableName -Throughput $newRUsTable `
    -Schema $schema
