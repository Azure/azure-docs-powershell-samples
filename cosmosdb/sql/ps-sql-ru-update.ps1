# Update RU for an Azure Cosmos DB SQL (Core) API database or container
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$databaseName = "database1"
$containerName = "container1"
$databaseResourceName = $accountName + "/sql/" + $databaseName + "/throughput"
$containerResourceName = $accountName + "/sql/" + $databaseName + "/" + $containerName + "/throughput"
$throughput = 500
$updateResource = "database" # or "container"

$properties = @{
    "resource"=@{"throughput"=$throughput}
}

if($updateResource -eq "database"){
Set-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases/settings" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName -PropertyObject $properties
}
elseif($updateResource -eq "container"){
Set-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases/containers/settings" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $containerResourceName -PropertyObject $properties
}
else {
    Write-Host("Must select database or container")
}