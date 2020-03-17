# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update database shared or graph dedicated throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "cosmos" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$databaseName = "mydatabase"
$graphName = "mygraph"
$newRUs = 400
$updateResource = "graph" # "database" or "graph"

if($updateResource -eq "database"){
    Write-Host "Updating database throughput"
    Set-AzCosmosDBGremlinDatabase -ResourceGroupName $resourceGroupName `
        -AccountName $accountName -Name $databaseName `
        -Throughput $newRUs
}
elseif($updateResource -eq "graph"){
    Write-Host "Updating graph throughput"
    # Get existing graph object first so we can access partition key
    # properties, which are required params for Set-AzCosmosDBGremlinGraph
    $graph = Get-AzCosmosDBGremlinGraph -ResourceGroupName $resourceGroupName `
        -AccountName $accountName -DatabaseName $databaseName `
        -Name $graphName -Detailed
    
    Set-AzCosmosDBGremlinGraph -ResourceGroupName $resourceGroupName `
        -AccountName $accountName -DatabaseName $databaseName `
        -Name $graphName `
        -Throughput $newRUs `
        -PartitionKeyKind $graph.Resource.PartitionKey.Kind `
        -PartitionKeyPath $graph.Resource.PartitionKey.Paths
}
