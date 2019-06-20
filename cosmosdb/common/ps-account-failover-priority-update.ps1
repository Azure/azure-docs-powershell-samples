# Change the failover priority for a single-master Azure Cosmos Account
# Note: Updating location with failoverPriority = 0 triggers a failover to the new region

$location = "West US 2"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount" # must be lower case.
$resourceType = "Microsoft.DocumentDb/databaseAccounts"
$apiVersion = "2015-04-08"

# Provision a new Cosmos account with the regions below
$locations = @(
    @{ "locationName"="West US 2"; "failoverPriority"=0 },
    @{ "locationName"="East US 2"; "failoverPriority"=1 }
)

$CosmosDBProperties = @{
    "databaseAccountOfferType"="Standard";
    "locations"=$locations
}

New-AzResource -ResourceType $resourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName -Location $location `
    -Name $accountName -PropertyObject $CosmosDBProperties

# Change the failover priority. Updating write region which will trigger a failover
Read-Host -Prompt "Press any key to change the failover priority"

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
