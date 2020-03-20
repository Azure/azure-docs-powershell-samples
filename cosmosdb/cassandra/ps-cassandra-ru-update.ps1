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

# Schema columns to create schema instance
# Prepare schema as it is mandatory parameter to Set-AzCosmosDBCassandraTable
# Eventually replace this with retrieval of existing schema using
# Get-AzCosmosDBCassandraTable, .Resource.Schema
$partitionKeys = @("machine", "cpu", "mtime")
$clusterKeys = @( 
    @{ name = "loadid"; orderBy = "Asc" };
    @{ name = "duration"; orderBy = "Desc" }
)
$columns = @(
    @{ name = "loadid"; type = "uuid" };
    @{ name = "machine"; type = "uuid" };
    @{ name = "cpu"; type = "int" };
    @{ name = "mtime"; type = "int" };
    @{ name = "load"; type = "float" };
    @{ name = "duration"; type = "float" }
)
# --------------------------------------------------

$throughput = Get-AzCosmosDBCassandraTableThroughput `
    -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -KeyspaceName $keyspaceName `
    -Name $tableName

# Get-AzCosmosDBCassandraTableThroughput emits ThroughputSettingsGetPropertiesResource
# Other APIs' Get-AzCosmosDB[Container]Throughput cmdlets emit PSThroughputSettingsGetResults
# Eventually transition these to $throughput.Throughput and $throughput.MinimumThroughput
# if Get-AzCosmosDBCassandraTableThroughput output conforms to other cmdlets
$currentRUs = $throughput.Resource.Throughput
$minimumRUs = $throughput.Resource.MinimumThroughput

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
    # Get-AzCosmosDBCassandraTable does not currently retrieve existing schema, so recreate it explicitly.
    # Eventually transition to using existing schema rather than re-specifying just for throughput update.
    # $table = Get-AzCosmosDBCassandraTable `
    #     -ResourceGroupName $resourceGroupName `
    #     -AccountName $accountName -KeyspaceName $keyspaceName `
    #     -Name $tableName
    # $schema = $table.Resource.Schema

    # Table Schema
    $psClusterKeys = @()
    ForEach ($clusterKey in $clusterKeys) {
        $psClusterKeys += New-AzCosmosDBCassandraClusterKey -Name $clusterKey.name -OrderBy $clusterKey.orderBy
    }

    $psColumns = @()
    ForEach ($column in $columns) {
        $psColumns += New-AzCosmosDBCassandraColumn -Name $column.name -Type $column.type
    }

    $schema = New-AzCosmosDBCassandraSchema `
        -PartitionKey $partitionKeys `
        -ClusterKey $psClusterKeys `
        -Column $psColumns

    Set-AzCosmosDBCassandraTable -ResourceGroupName $resourceGroupName `
        -AccountName $accountName -KeyspaceName $keyspaceName `
        -Name $tableName -Throughput $newRUs `
        -Schema $schema
}
