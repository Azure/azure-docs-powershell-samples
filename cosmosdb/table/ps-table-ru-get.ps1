# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Get RU/s throughput for Azure Cosmos DB Table API table
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "cosmos" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$tableName = "mytable"
# --------------------------------------------------

Get-AzCosmosDBTableThroughput -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $tableName
