# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Create Cosmos Gremlin API account, database, and graph with multi-master enabled,
# a database with shared thoughput, and a graph with dedicated throughput,
# and conflict resolution policy with last writer wins and custom resolver path
# --------------------------------------------------
Function New-RandomString{Param ([Int]$Length = 10) return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))}
# --------------------------------------------------
$uniqueId = New-RandomString -Length 7 # Random alphanumeric string for unique resource names
$apiKind = "Gremlin"
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$locations = @("East US", "West US") # Regions ordered by failover priority
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "cosmos-$uniqueId" # Must be all lower case
$consistencyLevel = "Session"
$tags = @{Tag1 = "MyTag1"; Tag2 = "MyTag2"; Tag3 = "MyTag3"}
$databaseName = "myDatabase"
$graphName = "myGraph"
$graphRUs = 400
$partitionKeys = @("/myPartitionKey")
$conflictResolutionPath = "/myResolutionPath"
# --------------------------------------------------
# Account
Write-Host "Creating account $accountName"
# Gremlin not yet supported in New-AzCosmosDBAccount
# $account = New-AzCosmosDBAccount -ResourceGroupName $resourceGroupName `
    # -Location $locations -Name $accountName -ApiKind $apiKind -Tag $tags `
    # -DefaultConsistencyLevel $consistencyLevel `
    # -EnableAutomaticFailover:$true
# --------------------------------------------------
# Account creation: use New-AzResource with property object
$azAccountResourceType = "Microsoft.DocumentDb/databaseAccounts"
$azApiVersion = "2020-03-01"
$azApiType = "EnableGremlin"

$azLocations = @()
$i = 0
ForEach ($location in $locations) {
    $azLocations += @{ locationName = "$location"; failoverPriority = $i++ }
}

$azConsistencyPolicy = @{
    defaultConsistencyLevel = "$consistencyLevel";
}

$azAccountProperties = @{
    capabilities = @( @{ name = "$azApiType" } );
    databaseAccountOfferType = "Standard";
    locations = $azLocations;
    consistencyPolicy = $azConsistencyPolicy;
    enableAutomaticFailover = "true";
}

New-AzResource -ResourceType $azAccountResourceType -ApiVersion $azApiVersion `
    -ResourceGroupName $resourceGroupName -Location $locations[0] `
    -Name $accountName -PropertyObject $azAccountProperties `
    -Tag $tags -Force

Write-Host "Creating database $databaseName"
$database = Set-AzCosmosDBGremlinDatabase -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $databaseName

# Graph
$conflictResolutionPolicy = New-AzCosmosDBGremlinConflictResolutionPolicy `
    -Type LastWriterWins -Path $conflictResolutionPath

Write-Host "Creating graph $graphName"
$graph = Set-AzCosmosDBGremlinGraph -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -DatabaseName $databaseName `
    -Name $graphName -Throughput $graphRUs `
    -PartitionKeyKind Hash -PartitionKeyPath $partitionKeys `
    -ConflictResolutionPolicy $conflictResolutionPolicy
