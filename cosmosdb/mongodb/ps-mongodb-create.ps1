# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Create Cosmos MongoDB API account with automatic failover,
# a database, and a collection with dedicated throughput.
# --------------------------------------------------
Function New-RandomString{Param ([Int]$Length = 10) return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))}
# --------------------------------------------------
$uniqueId = New-RandomString -Length 7 # Random alphanumeric string for unique resource names
$apiKind = "MongoDB"
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$locations = @("East US", "West US") # Regions ordered by failover priority
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "cosmos-$uniqueId" # Must be all lower case
$consistencyLevel = "Session"
$tags = @{Tag1 = "MyTag1"; Tag2 = "MyTag2"; Tag3 = "MyTag3"}
$databaseName = "myDatabase"
$collectionName = "myCollection"
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
    -EnableAutomaticFailover:$true

Write-Host "Creating database $databaseName"
$database = New-AzCosmosDBMongoDBDatabase -ParentObject $account `
    -Name $databaseName

$index1 = New-AzCosmosDBMongoDBIndex -Key $partitionKeys -Unique $true
$index2 = New-AzCosmosDBMongoDBIndex -Key $ttlKeys -TtlInSeconds $ttlInSeconds
$indexes = @($index1, $index2)

Write-Host "Creating collection $collectionName"
$collection = New-AzCosmosDBMongoDBCollection -ParentObject $database `
    -Name $collectionName -Throughput $collectionRUs `
    -Shard $shardKey -Index $indexes
