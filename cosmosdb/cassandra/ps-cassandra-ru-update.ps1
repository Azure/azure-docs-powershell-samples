# Update RU for an Azure Cosmos Cassandra API keyspace or table
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$keyspaceName = "keyspace1"
$tableName = "table1"
$keyspaceResourceName = $accountName + "/cassandra/" + $keyspaceName + "/throughput"
$tableResourceNAme = $accountName + "/cassandra/" + $keyspaceName + "/" + $tableName + "/throughput"
$throughput = 500
$updateResource = "keyspace" # or "table"

$properties = @{
    "resource"=@{"throughput"=$throughput}
}

if($updateResource -eq "keyspace"){
    Set-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/settings" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $keyspaceResourceName -PropertyObject $properties
}
elseif($updateResource -eq "table"){
Set-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/tables/settings" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $tableResourceNAme -PropertyObject $tableProperties
}
else {
    Write-Host("Must select keyspace or table")    
}
