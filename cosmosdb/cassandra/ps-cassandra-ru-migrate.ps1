# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Migrate a keyspace or table to autoscale or standard (manual) throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$keyspaceName = "myKeyspace"
$tableName = "myTable"
# --------------------------------------------------

Write-Host "Migrate keyspace with standard throughput to autoscale throughput."
Invoke-AzCosmosDBCassandraKeyspaceThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $keyspaceName -ThroughputType Autoscale

Write-Host "Migrate keyspace with autoscale throughput to standard throughput."

Invoke-AzCosmosDBCassandraKeyspaceThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $keyspaceName -ThroughputType Manual

Write-Host "Migrate table with standard throughput to autoscale throughput."
Invoke-AzCosmosDBCassandraTableThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -KeyspaceName $keyspaceName -Name $tableName -ThroughputType Autoscale

Write-Host "Migrate table with autoscale throughput to standard throughput."
Invoke-AzCosmosDBCassandraTableThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -KeyspaceName $keyspaceName -Name $tableName -ThroughputType Manual
