# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update database shared or collection provisioned throughput
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$databaseName = "myDatabase"
$collectionName = "myCollection"
$newRUs = 500
$shardKey = "user_id"
$updateResource = "collection" # "database" or "collection"

if($updateResource -eq "database"){
    Write-Host "Updating database throughput"
    Set-AzCosmosDBMongoDBDatabase -ResourceGroupName $resourceGroupName `
        -AccountName $accountName -DatabaseName $databaseName `
        -Throughput $newRUs
}
elseif($updateResource -eq "collection"){
    Write-Host "Updating collection throughput"
    Set-AzCosmosDBMongoDBCollection -ResourceGroupName $resourceGroupName `
        -AccountName $accountName -DatabaseName $databaseName `
        -Name $collectionName -Throughput $newRUs `
        -Shard $shardKey
}
else {
    Write-Host("Must select database or collection")    
}
