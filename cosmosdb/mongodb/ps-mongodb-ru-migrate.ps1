# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Migrate a database or collection to autoscale or standard (manual) throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$databaseName = "myDatabase"
$collectionName = "myCollection"
# --------------------------------------------------

Write-Host "Migrate database with standard throughput to autoscale throughput."
Invoke-AzCosmosDBMongoDBDatabaseThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $databaseName -ThroughputType Autoscale

Write-Host "Migrate database with autoscale throughput to standard throughput."
Invoke-AzCosmosDBMongoDBDatabaseThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $databaseName -ThroughputType Manual

Write-Host "Migrate collection with standard throughput to autoscale throughput."
Invoke-AzCosmosDBMongoDBCollectionThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseName -Name $collectionName -ThroughputType Autoscale

Write-Host "Migrate collection with autoscale throughput to standard throughput."
Invoke-AzCosmosDBMongoDBCollectionThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseName -Name $collectionName -ThroughputType Manual
