# List and get operations for Azure Cosmos account Cassandra API

$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$keyspaceName = "keyspace1"
$tableName = "table1"
$accountResourceName = $accountName + "/cassandra/"
$keyspaceResourceName = $accountName + "/cassandra/" + $keyspaceName
$keyspaceResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces"
$tableResourceName = $accountName + "/cassandra/" + $keyspaceName + "/" + $tableName
$tableResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces/tables"


Read-Host -Prompt "List all Keyspaces in an account. Press Enter to continue"

# List all keyspaces in an account
Get-AzResource -ResourceType $keyspaceResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $accountResourceName  | Select-Object Properties

Read-Host -Prompt "Get a single Keyspace in an account. Press Enter to continue"

Get-AzResource -ResourceType $keyspaceResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $keyspaceResourceName | Select-Object Properties

Read-Host -Prompt "List all tables in an keyspace. Press Enter to continue"

Get-AzResource -ResourceType $tableResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $keyspaceResourceName | Select-Object Properties

Read-Host -Prompt "Get a single table in an keyspace. Press Enter to continue"

Get-AzResource -ResourceType $tableResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $tableResourceName | Select-Object Properties