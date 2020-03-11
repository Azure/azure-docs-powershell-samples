# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Create Cosmos SQL API account, database, and container with
# dedicated thoughput, indexing policy, unique key, and conflict resolution
# --------------------------------------------------
Function New-RandomString{Param ([Int]$Length = 10) return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))}
# --------------------------------------------------
$uniqueId = New-RandomString -Length 7 # Random alphanumeric string for unique resource names
$apiKind = "GlobalDocumentDB"
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$locations = @("East US", "West US") # Regions ordered by failover priority
$resourceGroupName = "cosmos" # Resource Group must already exist
$accountName = "cdb-$uniqueId" # Must be all lower case
$consistencyLevel = "Session"
$tags = @{Tag1 = "MyTag1"; Tag2 = "MyTag2"; Tag3 = "MyTag3"}
$databaseName = "MyDatabase"
$containerName = "MyContainer"
$containerRUs = 400
$indexPathIncluded = "/*"
$indexPathExcluded = "/myPathToNotIndex/*"
$partitionKeyPath = "/myPartitionKey"
$uniqueKeyPath = "/myUniqueKeyPath"
$conflictResolutionPath = "/myResolutionPath"
$ttlInSeconds = 120 # Set this to -1 (or don't use it at all) to never expire
# --------------------------------------------------
# Account
Write-Host "Creating account $accountName"
$account = New-AzCosmosDBAccount -ResourceGroupName $resourceGroupName `
	-Location $locations -Name $accountName -ApiKind $apiKind -Tag $tags `
	-DefaultConsistencyLevel $consistencyLevel -EnableAutomaticFailover

# Database
Write-Host "Creating database $databaseName"
$database = Set-AzCosmosDBSqlDatabase -InputObject $account -Name $databaseName

# Container
# Throughput should be 400 <= $containerRUs <= 100000 for dedicated
if (($containerRUs -lt 400) -or ($containerRUs -gt 100000)) { $containerRUs = 400 }

$uniqueKey = New-AzCosmosDBSqlUniqueKey -Path $uniqueKeyPath
$uniqueKeyPolicy = New-AzCosmosDBSqlUniqueKeyPolicy -UniqueKey $uniqueKey

$includedPathIndex = New-AzCosmosDBSqlIncludedPathIndex -DataType String -Precision -1 -Kind Hash
$includedPath = New-AzCosmosDBSqlIncludedPath -Path $indexPathIncluded -Index $includedPathIndex

$indexingPolicy = New-AzCosmosDBSqlIndexingPolicy `
	-IncludedPath $includedPath -ExcludedPath $indexPathExcluded `
	-IndexingMode Consistent -Automatic $true

$conflictResolutionPolicy = New-AzCosmosDBSqlConflictResolutionPolicy `
	-Type LastWriterWins -Path $conflictResolutionPath

Write-Host "Creating container $containerName"
$container = Set-AzCosmosDBSqlContainer `
	-InputObject $database -Name $containerName `
	-Throughput $containerRUs -IndexingPolicy $indexingPolicy `
	-PartitionKeyKind Hash -PartitionKeyPath $partitionKeyPath `
	-UniqueKeyPolicy $uniqueKeyPolicy `
	-ConflictResolutionPolicy $conflictResolutionPolicy `
	-TtlInSeconds $ttlInSeconds
