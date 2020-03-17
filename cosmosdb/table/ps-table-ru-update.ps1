# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update throughput on existing Azure Cosmos DB Table API table
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "cosmos" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$tableName = "mytable"
$tableRUs = 600 # New RU/s for the table
# --------------------------------------------------

Set-AzCosmosDBTable -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $tableName `
    -Throughput $tableRUs
