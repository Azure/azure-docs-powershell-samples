# Update RU for an Azure Cosmos MongoDB API database or collection
$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$databaseName = "database1"
$databaseThroughputResourceName = $accountName + "/mongodb/" + $databaseName + "/throughput"
$databaseThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/settings"
$collectionName = "collection1"
$collectionThroughputResourceName = $accountName + "/mongodb/" + $databaseName + "/" + $collectionName + "/throughput"
$collectionThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/containers/settings"
$throughput = 500
$updateResource = "database" # or "collection"

$properties = @{
    "resource"=@{"throughput"=$throughput}
}

if($updateResource -eq "database"){
    Set-AzResource -ResourceType $databaseThroughputResourceType `
        -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
        -Name $databaseThroughputResourceName -PropertyObject $properties
}
elseif($updateResource -eq "collection"){
    Set-AzResource -ResourceType $collectionThroughputResourceType `
        -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
        -Name $collectionThroughputResourceName -PropertyObject $properties
}
else {
    Write-Host("Must select database or collection")    
}