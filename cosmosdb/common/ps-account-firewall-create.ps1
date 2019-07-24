# Create an Azure Cosmos Account for SQL (Core) API with IP Firewall

#generate a random 10 character alphanumeric string to ensure unique resource names
$uniqueId=$(-join ((97..122) + (48..57) | Get-Random -Count 15 | % {[char]$_}))

$apiVersion = "2015-04-08"
$location = "West US 2"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount-$uniqueId" # must be lower case.
$resourceType = "Microsoft.DocumentDb/databaseAccounts"

$locations = @(
    @{ "locationName"="West US 2"; "failoverPriority"=0 },
    @{ "locationName"="East US 2"; "failoverPriority"=1 }
)

# Add an IP range filter to the properties
$ipRangeFilter = @{ "ipRangeFilter"="10.0.0.1" }

$consistencyPolicy = @{
    "defaultConsistencyLevel"="Session";
}

$accountProperties = @{
    "databaseAccountOfferType"="Standard";
    "locations"=$locations;
    "consistencyPolicy"=$consistencyPolicy;
    "ipRangeFilter"= $ipRangeFilter;
    "enableMultipleWriteLocations"="false"
}

New-AzResource -ResourceType $resourceType -ApiVersion $apiVersion `
    -ResourceGroupName $resourceGroupName -Location $location `
    -Name $accountName -PropertyObject $accountProperties
