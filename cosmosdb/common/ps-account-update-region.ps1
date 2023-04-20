# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update Cosmos DB account: Add an Azure region (location)
# NOTE: if adding a region to a single master account, do not change the first 
# region in the same operation. Change failover priority order in a
# separate operation.
# NOTE: this operation will return, but account updates may still be
# occurring. Check the account or Resource Group's activity log for status.
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case

# Regions ordered by failover priority, with each indicating whether AZ-enabled
# Region AZ status can be checked at https://azure.microsoft.com/global-infrastructure/regions/
$locations = @(
    @{name = "East US"; azEnabled = $true};
    @{name = "West US"; azEnabled = $false};
)
# --------------------------------------------------

Write-Host "Get Cosmos DB account"
$account = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $accountName

$i = 0
$locationObjects = @()

ForEach ($location in $locations) {
    $locationObjects += New-AzCosmosDBLocationObject -LocationName $location.name -IsZoneRedundant $location.azEnabled -FailoverPriority ($i++)
}

Write-Host "Update Cosmos DB account region(s)"
Update-AzCosmosDBAccountRegion -InputObject $account -LocationObject $locationObjects
