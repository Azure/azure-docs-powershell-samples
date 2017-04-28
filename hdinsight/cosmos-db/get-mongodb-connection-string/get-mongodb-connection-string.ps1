# Retrieve a connection string that can be used by a MongoDB client
Invoke-AzureRmResourceAction -Action listConnectionStrings `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName "<resource-group-name>" `
    -Name "<database-account-name>"