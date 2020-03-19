# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update database or container throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$databaseNameNoShared = "myDatabase" # Database without shared throughput
$databaseNameShared = "myDatabase2" # Database with shared throughput
$containerNameDedicated = "myContainer" # Container with dedicated throughput
$newRUsDatabase = 500
$newRUsContainer = 500
# --------------------------------------------------

# Update throughput for database with shared throughput
Write-Host "Updating database shared throughput"
Set-AzCosmosDBSqlDatabase -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $databaseNameShared `
    -Throughput $newRUsDatabase

# Update throughput for container with dedicated throughput
# Prepare Set-AzCosmosDBSqlContainer mandatory params by first getting
# existing container so we can access settings
$containerDedicated = Get-AzCosmosDBSqlContainer `
    -ResourceGroupName $resourceGroupName -AccountName $accountName `
    -DatabaseName $databaseNameNoShared -Name $containerNameDedicated

Write-Host "Updating container dedicated throughput"
Set-AzCosmosDBSqlContainer -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseNameNoShared `
    -Name $containerNameDedicated `
    -Throughput $newRUsContainer `
    -PartitionKeyKind $containerDedicated.Resource.PartitionKey.Kind `
    -PartitionKeyPath $containerDedicated.Resource.PartitionKey.Paths

