# Update RU for an Azure Cosmos Table API table
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$tableName = "table1"
$resourceName = $accountName + "/table/" + $tableName + "/throughput"
$throughput = 500

$tableProperties = @{
    "resource"=@{"throughput"=$throughput}
} 
Set-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/tables/settings" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $resourceName -PropertyObject $tableProperties