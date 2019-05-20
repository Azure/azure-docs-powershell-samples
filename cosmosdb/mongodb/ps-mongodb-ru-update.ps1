# Update RU for an Azure Cosmos MongoDB API database or collection
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$databaseName = "database1"
$collectionName = "collection1"
$databaseResourceName = $accountName + "/mongodb/" + $databaseName + "/throughput"
$collectionResourceName = $accountName + "/mongodb/" + $databaseName + "/" + $collectionName + "/throughput"
$throughput = 500
$updateResource = "database" # or "collection"

$properties = @{
    "resource"=@{"throughput"=$throughput}
}

if($updateResource -eq "database"){
    Set-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases/settings" `
        -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
        -Name $databaseResourceName -PropertyObject $properties
}
elseif($updateResource -eq "collection"){
    Set-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases/collections/settings" `
        -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
        -Name $collectionResourceName -PropertyObject $properties
}
else {
    Write-Host("Must select database or collection")    
}