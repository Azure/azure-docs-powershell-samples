# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Show list and get operations for accounts, keyspaces, and tables
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$keyspaceName = "mykeyspace"
$tableName = "mytable"
# --------------------------------------------------

Write-Host "List all accounts in a resource group"
Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName

Write-Host "Get an account in a resource group"
Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName `
    -Name $accountName

Write-Host "List all keyspaces in an account"
Get-AzCosmosDBCassandraKeyspace -ResourceGroupName $resourceGroupName `
    -AccountName $accountName

Write-Host "Get a keyspace in an account"
Get-AzCosmosDBCassandraKeyspace -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $keyspaceName

Write-Host "List all tables in a keyspace"
Get-AzCosmosDBCassandraTable -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -KeyspaceName $keyspaceName

Write-Host "Get a table in a keyspace"
Get-AzCosmosDBCassandraTable -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -KeyspaceName $keyspaceName `
    -Name $tableName
