# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Create Cosmos Cassandra API account, keyspace, and table with multi-master enabled,
# a keyspace with shared thoughput, and a table with defined schema, dedicated throughput,
# and conflict resolution policy with last writer wins and custom resolver path
# --------------------------------------------------
Function New-RandomString{Param ([Int]$Length = 10) return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))}
# --------------------------------------------------
$uniqueId = New-RandomString -Length 7 # Random alphanumeric string for unique resource names
$apiKind = "Cassandra"
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$locations = @("East US", "West US") # Regions ordered by failover priority
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "cosmos-$uniqueId" # Must be all lower case
$consistencyLevel = "BoundedStaleness"
$maxStalenessInterval = 300
$maxStalenessPrefix = 100000
$tags = @{Tag1 = "MyTag1"; Tag2 = "MyTag2"; Tag3 = "MyTag3"}
$keyspaceName = "myKeyspace"
$keyspaceRUs = 400
$tableName = "myTable"
$tableRUs = 400
$partitionKeys = @("machine", "cpu", "mtime")
$clusterKeys = @( 
    @{ name = "loadid"; orderBy = "Asc" };
    @{ name = "duration"; orderBy = "Desc" }
)
$columns = @(
    @{ name = "loadid"; type = "uuid" };
    @{ name = "machine"; type = "uuid" };
    @{ name = "cpu"; type = "int" };
    @{ name = "mtime"; type = "int" };
    @{ name = "load"; type = "float" };
    @{ name = "duration"; type = "float" }
)
# --------------------------------------------------
# Account
Write-Host "Creating account $accountName"
# Cassandra not yet supported in New-AzCosmosDBAccount
# $account = New-AzCosmosDBAccount -ResourceGroupName $resourceGroupName `
    # -Location $locations -Name $accountName -ApiKind $apiKind -Tag $tags `
    # -DefaultConsistencyLevel $consistencyLevel `
    # -MaxStalenessIntervalInSeconds $maxStalenessInterval `
    # -MaxStalenessPrefix $maxStalenessPrefix `
    # -EnableMultipleWriteLocations
# Account creation: use New-AzResource with property object
# --------------------------------------------------
$azAccountResourceType = "Microsoft.DocumentDb/databaseAccounts"
$azApiVersion = "2020-03-03"
$azApiType = "EnableCassandra"

$azLocations = @()
$i = 0
ForEach ($location in $locations) {
    $azLocations += @{ locationName = "$location"; failoverPriority = $i++ }
}

$azConsistencyPolicy = @{
    defaultConsistencyLevel = $consistencyLevel;
    maxIntervalInSeconds = $maxStalenessInterval;
    maxStalenessPrefix = $maxStalenessPrefix;
}

$azAccountProperties = @{
    capabilities = @( @{ name = $azApiType; } );
    databaseAccountOfferType = "Standard";
    locations = $azLocations;
    consistencyPolicy = $azConsistencyPolicy;
    enableMultipleWriteLocations = "true";
}

New-AzResource -ResourceType $azAccountResourceType -ApiVersion $azApiVersion `
    -ResourceGroupName $resourceGroupName -Location $locations[0] `
    -Name $accountName -PropertyObject $azAccountProperties `
    -Tag $tags -Force

$account = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $accountName
# --------------------------------------------------
# Powershell cmdlets for additional operations

# Keyspace
Write-Host "Creating keyspace $keyspaceName"
$keyspace = Set-AzCosmosDBCassandraKeyspace -InputObject $account `
    -Name $keyspaceName -Throughput $keyspaceRUs

# Table Schema
$psClusterKeys = @()
ForEach ($clusterKey in $clusterKeys) {
    $psClusterKeys += New-AzCosmosDBCassandraClusterKey -Name $clusterKey.name -OrderBy $clusterKey.orderBy
}

$psColumns = @()
ForEach ($column in $columns) {
    $psColumns += New-AzCosmosDBCassandraColumn -Name $column.name -Type $column.type
}

$schema = New-AzCosmosDBCassandraSchema `
    -PartitionKey $partitionKeys `
    -ClusterKey $psClusterKeys `
    -Column $psColumns

# Table
Write-Host "Creating table $tableName"
$table = Set-AzCosmosDBCassandraTable -InputObject $keyspace `
    -Name $tableName -Schema $schema -Throughput $tableRUs 
