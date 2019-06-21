# Get RU for an Azure Cosmos Gremlin API database or graph
$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$databaseThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/settings"
$graphThroughputResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/graphs/settings"
$accountName = "mycosmosaccount"
$databaseName = "database1"
$graphName = "graph1"
$databaseThroughputResourceName = $accountName + "/gremlin/" + $databaseName + "/throughput"
$graphThroughputResourceName = $accountName + "/gremlin/" + $databaseName + "/" + $graphName + "/throughput"

# Get the throughput for a database (returns RU/s or error if not set)
Get-AzResource -ResourceType $databaseThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseThroughputResourceName  | Select-Object Properties

if($error[0].Exception.Message.Split(",")[0].Split(":")[1].Replace("`"","") -eq "NotFound")
{
    Write-Host "Throughput not set on database resource"
    $error.Clear()
}

# Get the throughput for a graph (returns RU/s or error)
Get-AzResource -ResourceType $graphThroughputResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $graphThroughputResourceName  | Select-Object Properties

if($error[0].Exception.Message.Split(",")[0].Split(":")[1].Replace("`"","") -eq "NotFound")
{
    Write-Host "Throughput not set on graph resource"
    $error.Clear()
}