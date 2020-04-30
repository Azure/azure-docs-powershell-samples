# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Get keyspace or table throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$keyspaceName = "mykeyspace" # Keyspace with shared throughput
$tableName = "mytable" # Table with dedicated throughput
# --------------------------------------------------

Write-Host "Get keyspace shared throughput"
Get-AzCosmosDBCassandraKeyspaceThroughput -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $keyspaceName

Write-Host "Get table dedicated throughput"
Get-AzCosmosDBCassandraTableThroughput -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -KeyspaceName $keyspaceName `
    -Name $tableName
