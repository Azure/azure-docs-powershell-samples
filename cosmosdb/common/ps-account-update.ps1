# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update Cosmos SQL API account: Add an Azure region (location)
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "cosmos" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$locations = @("East US", "West US") # Regions ordered by failover priority
# --------------------------------------------------

# Get existing Cosmos DB account
$account = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $accountName

# Fails with null ref exception as source requires both -Location and -LocationObject to be passed
Update-AzCosmosDBAccountRegion -InputObject $account -Location $locations

## TODO below is to try to get around issue where Update-AzCosmosDBAccountRegion source requires
# both -Location and -LocationObject. Have not been able to get past eventual error 
# List of supplied locations is invalid ActivityId: [GUID]], Microsoft.Azure.Documents.Common/2.10.0
# When Update-AzCosmosDBAccountRegion accepts EITHER parameter without requiring BOTH
# will update this example to use the above approach passing -Location.

# Create location object array
$locationObjects = @()
$i = 0

ForEach ($name in $locations){
    $locationObjects += New-AzCosmosDBLocationObject -LocationName $name -FailoverPriority ($i++)
}

# Fails - whether location display names or names are used; whether AZ is specified or not,
# whether I pass different regions for -Location and -LcoationObject etc.
Update-AzCosmosDBAccountRegion -InputObject $account -Location $locations -LocationObject $locationObjects
