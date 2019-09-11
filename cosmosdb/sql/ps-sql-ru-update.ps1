# Update RU for an Azure Cosmos DB SQL (Core) API database or container

$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$databaseName = "database1"
$containerName = "container1"
$databaseThroughputResourceName = $accountName + "/sql/" + $databaseName + "/throughput"
$databaseThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/settings"
$containerThroughputResourceName = $accountName + "/sql/" + $databaseName + "/" + $containerName + "/throughput"
$containerThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/containers/settings"
$throughput = 500
$updateResource = "container" # or "database"

$properties = @{
    "resource"=@{"throughput"=$throughput}
}

if($updateResource -eq "database"){
Set-AzResource -ResourceType $databaseThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseThroughputResourceName -PropertyObject $properties
}
elseif($updateResource -eq "container"){
Set-AzResource -ResourceType $containerThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $containerThroughputResourceName -PropertyObject $properties
}
else {
    Write-Host("Must select database or container")
}
