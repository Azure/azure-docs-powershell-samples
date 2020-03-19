# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Show list and get operations for accounts, databases, and containers
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$databaseName = "myDatabase"
$containerName = "myContainer"
# --------------------------------------------------

Write-Host "List all accounts in a resource group"
Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName

Write-Host "Get an account in a resource group"
Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName `
    -Name $accountName

Write-Host "List all databases in an account"
Get-AzCosmosDBSqlDatabase -ResourceGroupName $resourceGroupName `
    -AccountName $accountName

Write-Host "Get a database in an account"
Get-AzCosmosDBSqlDatabase -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $databaseName

Write-Host "List all containers in an database"
Get-AzCosmosDBSqlContainer -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseName 

Write-Host "Get a container in a database"
Get-AzCosmosDBSqlContainer -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseName `
    -Name $containerName
