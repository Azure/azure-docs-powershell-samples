# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Create Cosmos SQL API account, database, and container with dedicated throughput and no indexing policy
# --------------------------------------------------
Function New-RandomString{Param ([Int]$Length = 10) return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))}
# --------------------------------------------------
$uniqueId = New-RandomString -Length 7 # Random alphanumeric string for unique resource names
$apiKind = "GlobalDocumentDB"
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$locations = @("East US", "West US") # Regions ordered by failover priority
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "cosmos-$uniqueId" # Must be all lower case
$consistencyLevel = "Session"
$tags = @{Tag1 = "MyTag1"; Tag2 = "MyTag2"; Tag3 = "MyTag3"}
$databaseName = "myDatabase"
$containerName = "myContainer"
$containerRUs = 400
$partitionKeyPath = "/myPartitionKey"
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

$indexingPolicy = New-AzCosmosDBSqlIndexingPolicy -IndexingMode None

Write-Host "Creating container $containerName"
$container = Set-AzCosmosDBSqlContainer `
	-InputObject $database -Name $containerName `
	-Throughput $containerRUs -IndexingPolicy $indexingPolicy `
	-PartitionKeyKind Hash -PartitionKeyPath $partitionKeyPath
