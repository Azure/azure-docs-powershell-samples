# Set the Azure resource group name and location
$resourceGroupName = "sparkcdb1"
$resourceGroupLocation = "East US 2"

# Create the resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation

# Database name
$DBName = "testcassandra"

# Write and read locations and priorities for the database
$locations = @(@{"locationName"="East US 2"; 
                 "failoverPriority"=0}, 
               @{"locationName"="North Central US"; 
                  "failoverPriority"=1})

# IP addresses that can access the database through the firewall
$iprangefilter = "10.0.0.1"

# Consistency policy
$consistencyPolicy = @{"defaultConsistencyLevel"="BoundedStaleness";
                       "maxIntervalInSeconds"="10"; 
                       "maxStalenessPrefix"="200"}

# Create an Azure Cosmos DB Cassandra API account
$Capability= "EnableCassandra”

$capabilities= @(@{"name"=$Capability})

# DB properties
$DBProperties = @{"databaseAccountOfferType"="Standard"; 
                          "locations"=$locations; 
                          "consistencyPolicy"=$consistencyPolicy;
                          "capabilities"=$capabilities; 
                          "ipRangeFilter"=$iprangefilter}


# Create the database
New-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
                    -ApiVersion "2015-04-08" `
                    -ResourceGroupName $resourceGroupName `
                    -Location $resourceGroupLocation `
                    -Name $DBName `
                    -PropertyObject $DBProperties
