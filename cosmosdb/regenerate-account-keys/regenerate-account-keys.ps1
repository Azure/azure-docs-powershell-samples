# Regenerate an account key for the database
Invoke-AzureRmResourceAction -Action regenerateKey `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName "<resource-group-name>" `
    -Name "<database-account-name>" `
    -Parameters @{"keyKind"="<key-kind>"}