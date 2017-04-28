# Retrieve the primary and secondary account keys
Invoke-AzureRmResourceAction -Action listKeys `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName "<resource-group-name>" `
    -Name "<database-account-name>"
