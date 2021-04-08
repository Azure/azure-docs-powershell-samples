# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Create Cosmos MongoDB API account with automatic failover,
# a database, and a collection with autoscale throughput.
# --------------------------------------------------
Function New-RandomString{Param ([Int]$Length = 10) return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))}
# --------------------------------------------------
$uniqueId = New-RandomString -Length 7 # Random alphanumeric string for unique resource names
$apiKind = "MongoDB"
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$locations = @()
$locations += New-AzCosmosDBLocationObject -LocationName "East Us" -FailoverPriority 0 -IsZoneRedundant 0
$locations += New-AzCosmosDBLocationObject -LocationName "West Us" -FailoverPriority 1 -IsZoneRedundant 0

$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "cosmos-$uniqueId" # Must be all lower case
$serverVersion = "3.6" #3.2 or 3.6
$consistencyLevel = "Session"
$databaseName = "myDatabase"
$collectionName = "myCollection"
$autoscaleMaxThroughput = 4000 #minimum = 4000
$shardKey = "user_id"
$partitionKeys = @("user_id", "user_address")
$ttlKeys = @("_ts")
$ttlInSeconds = 604800
# --------------------------------------------------
Write-Host "Creating account $accountName"
$account = New-AzCosmosDBAccount -ResourceGroupName $resourceGroupName `
    -LocationObject $locations -Name $accountName -ApiKind $apiKind `
    -DefaultConsistencyLevel $consistencyLevel `
    -EnableAutomaticFailover:$true -MongoDBServerVersion $serverVersion

Write-Host "Creating database $databaseName"
$database = New-AzCosmosDBMongoDBDatabase -ParentObject $account `
    -Name $databaseName

$index1 = New-AzCosmosDBMongoDBIndex -Key $partitionKeys -Unique $true
$index2 = New-AzCosmosDBMongoDBIndex -Key $ttlKeys -TtlInSeconds $ttlInSeconds
$indexes = @($index1, $index2)

Write-Host "Creating collection $collectionName"
$collection = New-AzCosmosDBMongoDBCollection -ParentObject $database `
    -Name $collectionName -AutoscaleMaxThroughput $autoscaleMaxThroughput `
    -Shard $shardKey -Index $indexes
