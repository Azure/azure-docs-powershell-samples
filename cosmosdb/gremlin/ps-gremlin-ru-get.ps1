# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Get keyspace or table throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "cosmos" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$databaseName = "mydatabase"
$graphName = "mygraph"
# --------------------------------------------------

Write-Host "Get database shared throughput"
Get-AzCosmosDBGremlinDatabaseThroughput -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $databaseName

Write-Host "Get graph dedicated throughput"
Get-AzCosmosDBGremlinGraphThroughput -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseName `
    -Name $graphName
