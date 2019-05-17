# List and get operations for Azure Cosmos account Cassandra API
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$keyspaceName = "keyspace1"
$tableName = "table1"
$accountResourceName = $accountName + "/cassandra/"
$keyspaceResourceName = $accountName + "/cassandra/" + $keyspaceName
$tableResourceName = $accountName + "/cassandra/" + $keyspaceName + "/" + $tableName


Read-Host -Prompt "List all Keyspaces in an account. Press Enter to continue"

# List all keyspaces in an account
Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $accountResourceName  | Select-Object Properties

Read-Host -Prompt "Get a single Keyspace in an account. Press Enter to continue"

Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $keyspaceResourceName | Select-Object Properties

Read-Host -Prompt "List all tables in an keyspace. Press Enter to continue"

Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/tables" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $keyspaceResourceName | Select-Object Properties

Read-Host -Prompt "Get a single table in an keyspace. Press Enter to continue"

Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/tables" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $tableResourceName | Select-Object Properties