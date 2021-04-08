# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Create Cosmos SQL API account, database, and container with autoscale throughput,
# --------------------------------------------------
Function New-RandomString{Param ([Int]$Length = 10) return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))}
# --------------------------------------------------
$uniqueId = New-RandomString -Length 7 # Random alphanumeric string for unique resource names
$apiKind = "Sql"
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$locations = @()
$locations += New-AzCosmosDBLocationObject -LocationName "East Us" -FailoverPriority 0 -IsZoneRedundant 0
$locations += New-AzCosmosDBLocationObject -LocationName "West Us" -FailoverPriority 1 -IsZoneRedundant 0

$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "cosmos-$uniqueId" # Must be all lower case
$consistencyLevel = "Session"
$databaseName = "myDatabase"
$containerName = "myContainer"
$autoscaleMaxThroughput = 4000 #minimum = 4000
$partitionKeyPath = "/myPartitionKey"

# --------------------------------------------------
Write-Host "Creating account $accountName"
$account = New-AzCosmosDBAccount -ResourceGroupName $resourceGroupName `
	-LocationObject $locations -Name $accountName -ApiKind $apiKind `
	-DefaultConsistencyLevel $consistencyLevel `
	-EnableAutomaticFailover:$true

Write-Host "Creating database $databaseName"
$database = New-AzCosmosDBSqlDatabase -ParentObject $account -Name $databaseName

Write-Host "Creating container $containerName"
$container = New-AzCosmosDBSqlContainer `
	-ParentObject $database -Name $containerName `
    -PartitionKeyKind Hash -PartitionKeyPath $partitionKeyPath `
    -AutoscaleMaxThroughput $autoscaleMaxThroughput
