# Update RU for an Azure Cosmos SQL Gremlin API database or graph
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$databaseName = "database1"
$graphName = "graph1"
$databaseResourceName = $accountName + "/gremlin/" + $databaseName + "/throughput"
$graphResourceName = $accountName + "/gremlin/" + $databaseName + "/" + $graphName + "/throughput"
$throughput = 500
$updateResource = "database" # or "graph"

$properties = @{
    "resource"=@{"throughput"=$throughput}
}

if($updateResource -eq "database"){
Set-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases/settings" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName -PropertyObject $properties
}
elseif($updateResource -eq "graph"){
Set-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases/graphs/settings" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $graphResourceName -PropertyObject $properties
}
else {
    Write-Host("Must select database or graph")    
}