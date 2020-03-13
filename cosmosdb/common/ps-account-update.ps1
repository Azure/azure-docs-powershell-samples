# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update Cosmos DB account: Add an Azure region (location)
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "cosmos" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$locations = @("East US", "West US") # Regions ordered by failover priority
# --------------------------------------------------

# Get existing Cosmos DB account
# $account = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $accountName

# Fails with null ref exception as source requires both -Location and -LocationObject to be passed
# and there is a separate issue with -LocationObject
# Create location object array
# $locationObjects = @()
# $i = 0

# Update-AzCosmosDBAccountRegion -InputObject $account -Location $locations
# ForEach ($name in $locations){ $locationObjects += New-AzCosmosDBLocationObject -LocationName $name -FailoverPriority ($i++) }
# Update-AzCosmosDBAccountRegion -InputObject $account -LocationObject $locationObjects

# The following is to use Set-AzResource pending Update-AzCosmosDBAccountRegion fix
$resourceType = "Microsoft.DocumentDb/databaseAccounts"
$apiVersion = "2019-12-12"
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
