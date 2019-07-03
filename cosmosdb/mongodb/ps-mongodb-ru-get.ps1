# Get RU for an Azure Cosmos MongoDB API database or collection
$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$databaseThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/settings"
$collectionThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/collections/settings"
$accountName = "mycosmosaccount"
$databaseName = "database1"
$collectionName = "collection1"
$databaseThroughputResourceName = $accountName + "/mongodb/" + $databaseName + "/throughput"
$collectionThroughputResourceName = $accountName + "/mongodb/" + $databaseName + "/" + $collectionName + "/throughput"

# Get the throughput for a database (returns RU/s or 404 "Not found" error if not set)
Get-AzResource -ResourceType $databaseThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseThroughputResourceName  | Select-Object Properties

# Get the throughput for a collection (returns RU/s or 404 "Not found" error if not set)
Get-AzResource -ResourceType $collectionThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $collectionThroughputResourceName  | Select-Object Properties
