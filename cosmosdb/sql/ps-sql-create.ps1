# --------------------------------------------------
# References
# Az.CosmosDB + cmdlets used below | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Create a Cosmos SQL API account, a database with shared throughput, and two containers:
# One container with shared throughput, and one container with its own dedicated thoughput,
# custom indexing policy, a unique key, and user defined conflict resolution path
# --------------------------------------------------
Write-Host "Start:"(Get-Date -Format "O")
# --------------------------------------------------
# Functions / Utility
Function New-RandomString{Param ([Int]$Length = 10) return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))}

Function Get-VNetRuleId{Param ([String]$ResourceGroupName, [String]$VNetName, [String]$SubnetName)
	$vnet = Get-AzResource -Name $VNetName -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.Network/virtualNetworks"
	return ($vnet.ResourceId + "/subnets/" + $SubnetName)}
# --------------------------------------------------
$uniqueId = New-RandomString -Length 5	# Random alphanumeric string for unique resource names
$apiKind = "GlobalDocumentDB"
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$locations = @("East US")	# Regions ordered by failover priority; comma-separated
$resourceGroupName = "cosmos"

$accountName = "cdb-sql-$uniqueId"	# Must be all lower case
$consistencyLevel = "Session"
$tags = @{
	Department = "Snack Shack";
	Purpose = "The Counting of Beans";
	BillbackCode = 98765
}

$vnetName = "cosmos-vnet"	# Limit access to this VNet
$subnetName = "subnet1"	# Limit access to this subnet in VNet
$ignoreMissingVnetServiceEndpoint = $true	# Allow deployment if VNet does not have Cosmos DB service endpoint

$ipRanges = @("75.68.47.183", "8.8.8.8")	# Firewall allowed IP addresses/ranges

$databaseName = "db1"
$databaseRUs = 1000

$containerName1 = "shared_ru_container"
$partitionKeyPath1 = "/myPartitionKey1"

$containerName2 = "dedicated_ru_container"
$containerRUs2 = 400
$indexingPathIncluded2 = "/*"
$indexingPathExcluded2 = "/myPathToNotIndex/*"
$partitionKeyPath2 = "/myPartitionKey2"
$uniqueKeyPath2 = "/myUniqueKeyPath"
$conflictResolutionPath2 = "/myResolutionPath"
$ttlInSeconds2 = 100	# Set this to -1 (or don't use it at all) to never expire
# --------------------------------------------------
# VNet Access Restriction
$vnetRuleId = Get-VNetRuleId -ResourceGroupName $resourceGroupName -VNetName $vnetName -SubnetName $subnetName

$vnetRule1 = New-AzCosmosDBVirtualNetworkRule -Id $vnetRuleId -IgnoreMissingVNetServiceEndpoint $ignoreMissingVnetServiceEndpoint
$vnetRules = @($vnetRule1)	# Array of VNet rules
# --------------------------------------------------
# Deploy Resources

# Create Cosmos DB Account
# TODO: when firewall is enabled, toggle grant access to Azure networks
# TODO: when firewall is enabled, toggle portal access Data Explorer
# TODO: when VNet access restriction is enabled, also enable external access in addition to above firewall TODOs
#	-IpRangeFilter $ipRanges `
#	-EnableVirtualNetwork -VirtualNetworkRuleObject $vnetRules -VirtualNetworkRule @($vnetRuleId) `
$account = New-AzCosmosDBAccount `
	-ResourceGroupName $resourceGroupName `
	-Location $locations `
	-Name $accountName `
	-ApiKind $apiKind `
	-DefaultConsistencyLevel $consistencyLevel `
	-EnableAutomaticFailover `
	-EnableMultipleWriteLocations `
	-Tag $tags

# Create Cosmos DB Database
$database = Set-AzCosmosDBSqlDatabase `
	-InputObject $account `
	-Name $databaseName `
	-Throughput $databaseRUs

# Create Container with shared (from database) throughput
Set-AzCosmosDBSqlContainer `
	-InputObject $database `
	-Name $containerName1 `
	-PartitionKeyKind Hash `
	-PartitionKeyPath $partitionKeyPath1

# Create Container with dedicated throughput, indexing policy, unique key, conflict resolution policy
$uniqueKey2 = New-AzCosmosDBSqlUniqueKey -Path $uniqueKeyPath2
$uniqueKeyPolicy2 = New-AzCosmosDBSqlUniqueKeyPolicy -UniqueKey $uniqueKey2

$includedPathIndex2 = New-AzCosmosDBSqlIncludedPathIndex -DataType String -Precision -1 -Kind Hash
$includedPath2 = New-AzCosmosDBSqlIncludedPath -Path $indexingPathIncluded2 -Index $includedPathIndex2

$indexingPolicy2 = New-AzCosmosDBSqlIndexingPolicy `
	-IncludedPath $includedPath2 `
	-ExcludedPath $indexingPathExcluded2 `
	-IndexingMode Consistent `
	-Automatic $true

$conflictResolutionPolicy2 = New-AzCosmosDBSqlConflictResolutionPolicy `
	-Type LastWriterWins `
	-Path $conflictResolutionPath2

Set-AzCosmosDBSqlContainer `
	-InputObject $database `
	-Name $containerName2 `
	-IndexingPolicy $indexingPolicy2 `
	-Throughput $containerRUs2 `
	-PartitionKeyKind Hash `
	-PartitionKeyPath $partitionKeyPath2 `
	-UniqueKeyPolicy $uniqueKeyPolicy2 `
	-ConflictResolutionPolicy $conflictResolutionPolicy2 `
	-TtlInSeconds $ttlInSeconds2

Write-Host "Complete:"(Get-Date -Format "O")
