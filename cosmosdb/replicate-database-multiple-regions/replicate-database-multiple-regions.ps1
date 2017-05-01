# Set the Azure resource group name and location
$resourceGroupName = "mydbresourcegroup"
$resourceGroupLocation = "South Central US"

# Database name
$DBName = "testdb"
# Distribution locations
$locations = @(@{"locationName"="East US"; 
                 "failoverPriority"=2},
               @{"locationName"="West US"; 
                 "failoverPriority"=1},
               @{"locationName"="South Central US"; 
                 "failoverPriority"=0})

# Create the resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation

# Consistency policy
$consistencyPolicy = @{"maxIntervalInSeconds"="10"; 
                       "maxStalenessPrefix"="200"}

# DB properties
$DBProperties = @{"databaseAccountOfferType"="Standard";
                  "Kind"="GlobalDocumentDB"; 
                  "locations"=$locations; 
                  "consistencyPolicy"=$consistencyPolicy;}

# Create the database
New-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
                    -ApiVersion "2015-04-08" `
                    -ResourceGroupName $resourceGroupName `
                    -Location $resourceGroupLocation `
                    -Name $DBName `
                    -PropertyObject $DBProperties

# Modify locations/priorities
$newLocations = @(@{"locationName"="West US"; 
                 "failoverPriority"=0},
               @{"locationName"="East US"; 
                 "failoverPriority"=1},
               @{"locationName"="South Central US"; 
                 "failoverPriority"=2},
               @{"locationName"="North Central US";
                 "failoverPriority"=3})

# Updated properties
$updateDBProperties = @{"databaseAccountOfferType"="Standard";
                        "locations"=$newLocations;}

# Update the database with the properties
Set-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName `
    -Name $DBName `
    -PropertyObject $UpdateDBProperties
