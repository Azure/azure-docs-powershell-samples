# Update RU for an Azure Cosmos Table API table

$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$tableName = "table1"
$tableThroughputResourceName = $accountName + "/table/" + $tableName + "/throughput"
$tableThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/tables/settings"
$throughput = 500

$tableProperties = @{
    "resource"=@{"throughput"=$throughput}
} 
Set-AzResource -ResourceType $tableThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $tableThroughputResourceName -PropertyObject $tableProperties