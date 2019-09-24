# Create an Azure Cosmos Account for Gremlin API with multi-master enabled, shared database throughput,'
# dedicated graph throughput with last writer wins conflict policy and custom resolution path


#generate a random 10 character alphanumeric string to ensure unique resource names
$uniqueId=$(-join ((97..122) + (48..57) | Get-Random -Count 15 | % {[char]$_}))

$apiVersion = "2015-04-08"
$location = "West US 2"
$resourceGroupName = "MyResourceGroup"
$accountName = "mycosmosaccount-$uniqueId" # must be lower case.
$apiType = "EnableGremlin"
$accountResourceType = "Microsoft.DocumentDb/databaseAccounts"
$databaseName = "database1"
$databaseResourceName = $accountName + "/gremlin/" + $databaseName
$databaseResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases"
$graphName = "graph1"
$graphResourceName = $accountName + "/gremlin/" + $databaseName + "/" + $graphName
$graphResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/graphs"

# Create account
$locations = @(
    @{ "locationName"="West US 2"; "failoverPriority"=0 },
    @{ "locationName"="East US 2"; "failoverPriority"=1 }
)

$consistencyPolicy = @{ "defaultConsistencyLevel"="Session" }

$accountProperties = @{
    "capabilities"= @( @{ "name"=$apiType } );
    "databaseAccountOfferType"="Standard";
    "locations"=$locations;
    "consistencyPolicy"=$consistencyPolicy;
    "enableMultipleWriteLocations"="true"
}

New-AzResource -ResourceType $accountResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName -Location $location `
    -Name $accountName -PropertyObject $accountProperties -Force


# Create database with shared throughput
$databaseProperties = @{
    "resource"=@{ "id"=$databaseName };
    "options"=@{ "Throughput"= 400 }
}
New-AzResource -ResourceType $databaseResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName -PropertyObject $databaseProperties -Force


# Create a graph with a partition key, last writer wins conflict policy and custom conflict resolution path
$graphProperties = @{
    "resource"=@{
        "id"=$graphName; 
        "partitionKey"=@{
            "paths"=@("/myPartitionKey"); 
            "kind"="Hash"
        };
        "conflictResolutionPolicy"=@{
            "mode"="lastWriterWins"; 
            "conflictResolutionPath"="/myResolutionPath"
        }
    };
    "options"=@{ "Throughput"= 400 }
}
New-AzResource -ResourceType $graphResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $graphResourceName -PropertyObject $graphProperties  -Force
