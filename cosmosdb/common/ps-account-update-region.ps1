# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update Cosmos DB account: Add an Azure region (location)
# NOTE: if -adding a new- region to a single master account, do not change the first 
# region in the same operation. If -changing the failover priority- first set the
# needed regions on the account, then change failover priority.
# NOTE: this operation will return but account updates may still be
# occurring. Check the account or Resource Group's activity log for status.
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$locations = @("West US", "East US") # Regions ordered by failover priority
# --------------------------------------------------

# Get existing Cosmos DB account
# $account = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $accountName

# Eventually transition to Update-AzCosmosDBAccountRegion with -Location or -LocationObject
# Update-AzCosmosDBAccountRegion -InputObject $account -Location $locations
# ForEach ($name in $locations){ $locationObjects += New-AzCosmosDBLocationObject -LocationName $name -FailoverPriority ($i++) }
# Update-AzCosmosDBAccountRegion -InputObject $account -LocationObject $locationObjects

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
