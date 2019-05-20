# List and Get operations for Azure Cosmos Table API
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount" # must be lower case.
$tableName = "table1"
$accountResourceName = $accountName + "/table/"
$tableResourceName = $accountName + "/table/" + $tableName


Read-Host -Prompt "List all tables in an account. Press Enter to continue"

Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/tables" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $accountResourceName  | Select-Object Properties

Read-Host -Prompt "Get a table in an account. Press Enter to continue"

Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/tables" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $tableResourceName | Select-Object Properties