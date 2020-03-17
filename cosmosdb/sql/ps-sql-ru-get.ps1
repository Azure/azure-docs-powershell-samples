# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Get database or container throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "cosmos" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$databaseNameNoShared = "MyDatabase" # Database without shared throughput
$databaseNameShared = "MyDatabase2" # Database with shared throughput
$containerNameDedicated = "MyContainer" # Container with dedicated throughput
# --------------------------------------------------

Write-Host "Get database shared throughput"
Get-AzCosmosDBSqlDatabaseThroughput -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $databaseNameShared

Write-Host "Get container dedicated throughput"
Get-AzCosmosDBSqlContainerThroughput -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseNameNoShared `
    -Name $containerNameDedicated
