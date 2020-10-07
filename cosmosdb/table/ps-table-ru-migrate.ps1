# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Migrate a table to autoscale or standard (manual) throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$tableName = "myTable"
# --------------------------------------------------

Write-Host "Migrate table with standard throughput to autoscale throughput."
Invoke-AzCosmosDBTableThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $tableName -ThroughputType Autoscale

Write-Host "Migrate table with autoscale throughput to standard throughput."
Invoke-AzCosmosDBTableThroughputMigration -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $tableName -ThroughputType Manual
