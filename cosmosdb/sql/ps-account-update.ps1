# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update Cosmos DB account: Add an Azure region (location)
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$locations = @("East US", "West US") # Regions ordered by failover priority
# --------------------------------------------------

# Get existing Cosmos DB account
# $account = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $accountName

# Eventually transition to Update-AzCosmosDBAccountRegion with -Location or -LocationObject
# Update-AzCosmosDBAccountRegion -InputObject $account -Location $locations

# Use Set-AzResource with property object pending transition to Update-AzCosmosDBAccountRegion
$resourceType = "Microsoft.DocumentDb/databaseAccounts"
$apiVersion = "2020-03-01"
$locationObjects = @()
$i = 0
ForEach ($location in $locations) { $locationObjects += @{ locationName = "$location"; failoverPriority = $i++ } }
$CosmosDBProperties = @{
    databaseAccountOfferType = "Standard";
    locations = $locationObjects;
}

Set-AzResource -ResourceGroupName $resourceGroupName -ResourceType $resourceType `
    -ApiVersion $apiVersion -Name $accountName `
    -PropertyObject $CosmosDBProperties -Force
