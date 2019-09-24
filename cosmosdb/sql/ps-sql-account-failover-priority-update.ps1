# Change the failover priority for a single-master Azure Cosmos Account
# Note: Updating location with failoverPriority = 0 triggers a failover to the new region

#generate a random 10 character alphanumeric string to ensure unique resource names
$uniqueId=$(-join ((97..122) + (48..57) | Get-Random -Count 15 | % {[char]$_}))

$apiVersion = "2015-04-08"
$location = "West US 2"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount-$uniqueId" # must be lower case.
$resourceType = "Microsoft.DocumentDb/databaseAccounts"


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
    -ResourceGroupName $resourceGroupName -Name $accountName `
    -Parameters $failoverPolicies
