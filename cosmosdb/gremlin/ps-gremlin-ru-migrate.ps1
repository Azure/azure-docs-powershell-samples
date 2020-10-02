# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Migrate a database or graph to autoscale or standard (manual) throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$databaseName = "myDatabase"
$graphName = "myGraph"
# --------------------------------------------------

Write-Host "Migrate database with standard throughput to autoscale throughput."
Invoke-AzCosmosDBGremlinDatabaseThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $databaseName -ThroughputType Autoscale

Write-Host "Migrate database with autoscale throughput to standard throughput."
Invoke-AzCosmosDBGremlinDatabaseThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $databaseName -ThroughputType Manual

Write-Host "Migrate graph with standard throughput to autoscale throughput."
Invoke-AzCosmosDBGremlinGraphThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseName -Name $graphName -ThroughputType Autoscale

Write-Host "Migrate graph with autoscale throughput to standard throughput."
Invoke-AzCosmosDBGremlinGraphThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseName -Name $graphName -ThroughputType Manual
