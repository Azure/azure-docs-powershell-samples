# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Create Cosmos MongoDB API account, database, and collection with multi-master enabled,
# a database with shared thoughput, and a collection with dedicated throughput
# and conflict resolution policy with last writer wins and custom resolver path
# --------------------------------------------------
Function New-RandomString{Param ([Int]$Length = 10) return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))}
# --------------------------------------------------
$uniqueId = New-RandomString -Length 4 # Random alphanumeric string for unique resource names
$apiKind = "MongoDB"
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$locations = @("East US", "West US") # Regions ordered by failover priority
$resourceGroupName = "cosmos" # Resource Group must already exist
$accountName = "cdb-mongo-$uniqueId" # Must be all lower case
$consistencyLevel = "Session"
$tags = @{Tag1 = "MyTag1"; Tag2 = "MyTag2"; Tag3 = "MyTag3"}
$databaseName = "mydatabase"
$databaseRUs = 400
$collectionName = "mycollection"
$collectionRUs = 400
$shardKey = "user_id"
$partitionKeys = @("user_id", "user_address")
$ttlKeys = @("_ts")
$ttlInSeconds = 604800
# --------------------------------------------------
Write-Host "Creating account $accountName"
$account = New-AzCosmosDBAccount -ResourceGroupName $resourceGroupName `
    -Location $locations -Name $accountName -ApiKind $apiKind -Tag $tags `
    -DefaultConsistencyLevel $consistencyLevel `
    -EnableMultipleWriteLocations

Write-Host "Creating database $databaseName"
$database = Set-AzCosmosDBMongoDBDatabase -InputObject $account `
    -Name $databaseName -Throughput $databaseRUs

# Collection
$index1 = New-AzCosmosDBMongoDBIndex -Key $partitionKeys -Unique $true
$index2 = New-AzCosmosDBMongoDBIndex -Key $ttlKeys -TtlInSeconds $ttlInSeconds
$indexes = @($index1, $index2)

Write-Host "Creating collection $collectionName"
$collection = Set-AzCosmosDBMongoDBCollection -InputObject $database `
    -Name $collectionName -Throughput $collectionRUs `
    -Shard $shardKey -Index $indexes
