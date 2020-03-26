# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update container throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$databaseName = "myDatabase"
$containerName = "myContainer"
$newRUs = 500
# --------------------------------------------------

$throughput = Get-AzCosmosDBSqlContainerThroughput -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseName -Name $containerName

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

    # Prepare Set-AzCosmosDBSqlContainer mandatory params by first getting
    # existing container so we can access settings.
    $container = Get-AzCosmosDBSqlContainer `
        -ResourceGroupName $resourceGroupName `
        -AccountName $accountName -DatabaseName $databaseName `
        -Name $containerName

    # NOTE: if the container has a custom conflict resolution policy or
    # a unique key policy, those parameters must be provided here same
    # as when the container was created.
    Set-AzCosmosDBSqlContainer -ResourceGroupName $resourceGroupName `
        -AccountName $accountName -DatabaseName $databaseName `
        -Name $containerName -Throughput $newRUs `
        -PartitionKeyKind $container.Resource.PartitionKey.Kind `
        -PartitionKeyPath $container.Resource.PartitionKey.Paths
}
