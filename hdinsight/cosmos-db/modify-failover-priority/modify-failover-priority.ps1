# Write and read locations and priorities for the database
$failoverPolicies = @(@{"locationName"="<write-region-location>"; 
                        "failoverPriority"=0},
                      @{"locationName"="<read-region-location>"; 
                        "failoverPriority"=1})

# Update an existing database with the failover policies
Invoke-AzureRmResourceAction -Action failoverPriorityChange `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName "<resource-group-name>" `
    -Name "<database-account-name>" `
    -Parameters @{"failoverPolicies"=$failoverPolicies}
