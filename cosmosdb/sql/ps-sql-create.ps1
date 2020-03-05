# --------------------------------------------------
# References
# Az.CosmosDB + cmdlets used below | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Create a Cosmos SQL API account, a database with shared throughput, and a container with
# dedicated thoughput, indexing policy, a unique key, and user defined conflict resolution path
# --------------------------------------------------
# Functions / Utility
Function New-RandomString{Param ([Int]$Length = 10) return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))}
# --------------------------------------------------
$uniqueId = New-RandomString -Length 5 # Random alphanumeric string for unique resource names
$apiKind = "GlobalDocumentDB"
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$locations = @("East US", "West US") # Regions ordered by failover priority
$resourceGroupName = "cosmos-db-rg" # Resource Group must already exist
$accountName = "cosmos-db-$uniqueId" # Must be all lower case
$consistencyLevel = "Session"
$tags = @{Tag1 = "Tag1Text"; Tag2 = "Tag2Text"; Tag3 = "Tag3Text"}
$databaseName = "myDatabase"
$databaseRUs = 400
$containerName = "myContainer"
$containerRUs = 400
$indexPathIncluded = "/*"
$indexPathExcluded = "/myPathToNotIndex/*"
$partitionKeyPath = "/myPartitionKey"
$uniqueKeyPath = "/myUniqueKeyPath"
$conflictResolutionPath = "/myResolutionPath"
$ttlInSeconds = 100 # Set this to -1 (or don't use it at all) to never expire
# --------------------------------------------------
# Cosmos DB Account
$account = New-AzCosmosDBAccount `
	-ResourceGroupName $resourceGroupName `
	-Location $locations `
	-Name $accountName `
	-ApiKind $apiKind `
	-DefaultConsistencyLevel $consistencyLevel `
	-EnableAutomaticFailover `
	-Tag $tags

# Cosmos DB Database
$database = Set-AzCosmosDBSqlDatabase `
	-InputObject $account `
	-Name $databaseName `
	-Throughput $databaseRUs

# Container with dedicated throughput, unique key, indexing policy, conflict resolution policy
$uniqueKey = New-AzCosmosDBSqlUniqueKey -Path $uniqueKeyPath
$uniqueKeyPolicy = New-AzCosmosDBSqlUniqueKeyPolicy -UniqueKey $uniqueKey

$includedPathIndex = New-AzCosmosDBSqlIncludedPathIndex -DataType String -Precision -1 -Kind Hash
$includedPath = New-AzCosmosDBSqlIncludedPath -Path $indexPathIncluded -Index $includedPathIndex

$indexingPolicy = New-AzCosmosDBSqlIndexingPolicy `
	-IncludedPath $includedPath `
	-ExcludedPath $indexPathExcluded `
	-IndexingMode Consistent `
	-Automatic $true

$conflictResolutionPolicy = New-AzCosmosDBSqlConflictResolutionPolicy `
	-Type LastWriterWins `
	-Path $conflictResolutionPath

Set-AzCosmosDBSqlContainer `
	-InputObject $database `
	-Name $containerName `
	-IndexingPolicy $indexingPolicy `
	-Throughput $containerRUs `
	-PartitionKeyKind Hash `
	-PartitionKeyPath $partitionKeyPath `
	-UniqueKeyPolicy $uniqueKeyPolicy `
	-ConflictResolutionPolicy $conflictResolutionPolicy `
	-TtlInSeconds $ttlInSeconds
