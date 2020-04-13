# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update table throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$keyspaceName = "mykeyspace"
$tableName = "mytable"
$newRUs = 500
# --------------------------------------------------
$throughput = Get-AzCosmosDBCassandraTableThroughput -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -KeyspaceName $keyspaceName -Name $tableName

$currentRUs = $throughput.Throughput
$minimumRUs = $throughput.MinimumThroughput

Write-Host "Current throughput is $currentRUs. Minimum allowed throughput is $minimumRUs."

if ([int]$newRUs -lt [int]$minimumRUs) {
    Write-Host "Requested new throughput of $newRUs is less than minimum allowed throughput of $minimumRUs."
    Write-Host "Using minimum allowed throughput of $minimumRUs instead."
    $newRUs = $minimumRUs
}

if ([int]$newRUs -eq [int]$currentRUs) {
    Write-Host "New throughput is the same as current throughput. No change needed."
}
else {
    Write-Host "Updating throughput to $newRUs."

    # Set-AzCosmosDBCassandraTable requires -Schema parameter.
    # Retrieve existing schema so we can pass it back to Set-AzCosmosDBCassandraTable
    $table = Get-AzCosmosDBCassandraTable `
        -ResourceGroupName $resourceGroupName `
        -AccountName $accountName -KeyspaceName $keyspaceName `
        -Name $tableName

    $schema = $table.Resource.Schema

    Set-AzCosmosDBCassandraTable -ResourceGroupName $resourceGroupName `
        -AccountName $accountName -KeyspaceName $keyspaceName `
        -Name $tableName -Throughput $newRUs `
        -Schema $schema
}
