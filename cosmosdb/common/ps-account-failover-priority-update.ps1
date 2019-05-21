# Change the failover priority for an Azure Cosmos Account
# Assume West US = 0 and East US = 1, the script below will flip them
# Updating location with failoverPriority = 0 will trigger a failover
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"

$failoverRegions = @(
    @{ "locationName"="East US"; "failoverPriority"=0 },
    @{ "locationName"="West US"; "failoverPriority"=1 }
)

$failoverPolicies = @{ 
    "failoverPolicies"= $failoverRegions
}

Invoke-AzResourceAction -Action failoverPriorityChange `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName -Name $accountName -Parameters $failoverPolicies