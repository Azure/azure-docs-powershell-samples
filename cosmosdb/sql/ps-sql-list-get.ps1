# List and Get operations for Cosmos SQL API
$apiVersion = "2015-04-08"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$accountResourceName = $accountName + "/sql/"
$databaseName = "database1"
$databaseResourceName = $accountName + "/sql/" + $databaseName
$databaseResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases"
$containerName = "container1"
$containerResourceName = $accountName + "/sql/" + $databaseName + "/" + $containerName
$containerResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/containers"


Read-Host -Prompt "List all databases in an account. Press Enter to continue"

Get-AzResource -ResourceType $databaseResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $accountResourceName  | Select-Object Properties

Read-Host -Prompt "Get a database in an account. Press Enter to continue"

Get-AzResource -ResourceType $databaseResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName | Select-Object Properties

Read-Host -Prompt "List all containers in a database. Press Enter to continue"

Get-AzResource -ResourceType $containerResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName | Select-Object Properties

Read-Host -Prompt "Get a container in a database. Press Enter to continue"

Get-AzResource -ResourceType $containerResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $containerResourceName | Select-Object Properties
