# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update keyspace or table throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "cosmos" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$keyspaceName = "ks1"
$tableName = "t1"
$newRUsKeyspace = 800
$newRUsTable = 600

# Schema columns to create schema instance
# Prepare schema as it is mandatory parameter to Set-AzCosmosDBCassandraTable
# Eventually replace this with retrieval of existing schema using
# Get-AzCosmosDBCassandraTable, .Resource.Schema
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

# Get-AzCosmosDBCassandraTable does not currently retrieve schema
# Eventually transition to this approach
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
