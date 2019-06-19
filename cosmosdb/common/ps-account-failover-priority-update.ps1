# Change the failover priority for a single-master Azure Cosmos Account
# Assume West US 2 = 0 and East US 2 = 1, the script below will flip them
# Note: Updating location with failoverPriority = 0 triggers a failover to the new region
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount"
$resourceType = "Microsoft.DocumentDb/databaseAccounts"
$apiVersion = "2015-04-08"

$failoverRegions = @(
    @{ "locationName"="East US 2"; "failoverPriority"=0 },
    @{ "locationName"="West US 2"; "failoverPriority"=1 }
)

$failoverPolicies = @{ 
    "failoverPolicies"= $failoverRegions
}

Invoke-AzResourceAction -Action failoverPriorityChange `
    -ResourceType $resourceType -ApiVersion $apiVersion `
    -ResourceGroupName $resourceGroupName -Name $accountName -Parameters $failoverPolicies
