# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Update Cosmos DB account: Change region failover priority.
# Note: updating location at priority 0 triggers a failover to the new location
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "myaccount" # Must be all lower case
$locations = @("West US", "East US") # Regions ordered by UPDATED failover priority
# --------------------------------------------------

# Get existing Cosmos DB account
$account = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $accountName

# Update account failover priority
Update-AzCosmosDBAccountFailoverPriority -InputObject $account -FailoverPolicy $locations
