# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# List and get operations for accounts, databases, and graphs
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$databaseName = "myDatabase"
$graphName = "myGraph"
# --------------------------------------------------

Write-Host "List all accounts in a resource group"
Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName

Write-Host "Get an account in a resource group"
Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName `
    -Name $accountName

Write-Host "List all databases in an account"
Get-AzCosmosDBGremlinDatabase -ResourceGroupName $resourceGroupName `
    -AccountName $accountName

Write-Host "Get a database in an account"
Get-AzCosmosDBGremlinDatabase -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $databaseName

Write-Host "List all graphs in a database"
Get-AzCosmosDBGremlinGraph -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseName 

Write-Host "Get a graph in a database"
Get-AzCosmosDBGremlinGraph -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseName `
    -Name $graphName
