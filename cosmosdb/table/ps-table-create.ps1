# Reference: Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# --------------------------------------------------
# Purpose
# Create Cosmos Table API account and a Table
# --------------------------------------------------
Function New-RandomString{Param ([Int]$Length = 10) return $(-join ((97..122) + (48..57) | Get-Random -Count $Length | ForEach-Object {[char]$_}))}
# --------------------------------------------------
$uniqueId = New-RandomString -Length 7 # Random alphanumeric string for unique resource names
$apiKind = "Table"
# --------------------------------------------------
# Variables - ***** SUBSTITUTE YOUR VALUES *****
$locations = @("East US", "West US") # Regions ordered by failover priority
$resourceGroupName = "myResourceGroup" # Resource Group must already exist
$accountName = "cosmos-$uniqueId" # Must be all lower case
$consistencyLevel = "Session"
$tags = @{Tag1 = "MyTag1"; Tag2 = "MyTag2"; Tag3 = "MyTag3"}
$tableName = "myTable"
$tableRUs = 400
# --------------------------------------------------
# Account
Write-Host "Creating account $accountName"
# Cassandra not yet supported in New-AzCosmosDBAccount
# $account = New-AzCosmosDBAccount -ResourceGroupName $resourceGroupName `
    # -Location $locations -Name $accountName -ApiKind $apiKind -Tag $tags `
    # -DefaultConsistencyLevel $consistencyLevel
# Account creation: use New-AzResource with property object
# --------------------------------------------------
$azAccountResourceType = "Microsoft.DocumentDb/databaseAccounts"
$azApiVersion = "2019-12-12"
$azApiType = "EnableTable"

$azLocations = @()
$i = 0
ForEach ($location in $locations) {
    $azLocations += @{ locationName = "$location"; failoverPriority = $i++ }
}

$azConsistencyPolicy = @{
    defaultConsistencyLevel = "$consistencyLevel";
}

$azAccountProperties = @{
    capabilities= @( @{ name = $azApiType } );
    databaseAccountOfferType = "Standard";
    locations = $azLocations;
    consistencyPolicy = $azConsistencyPolicy;
    enableMultipleWriteLocations = "false";
}

New-AzResource -ResourceType $azAccountResourceType -ApiVersion $azApiVersion `
    -ResourceGroupName $resourceGroupName -Location $locations[0] `
    -Name $accountName -PropertyObject $azAccountProperties `
    -Tag $tags -Force

Write-Host "Creating Table $tableName"

Set-AzCosmosDBTable -ResourceGroupName $resourceGroupName `
    -AccountName $accountName -Name $tableName `
    -Throughput $tableRUs
