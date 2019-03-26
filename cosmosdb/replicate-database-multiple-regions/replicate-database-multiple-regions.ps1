# Set the Azure resource group name and location
$resourceGroupName = "myResourceGroup"
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
New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation

# Consistency policy
$consistencyPolicy = @{"maxIntervalInSeconds"="10"; 
                       "maxStalenessPrefix"="200"}

# DB properties
$DBProperties = @{"databaseAccountOfferType"="Standard";
                  "Kind"="GlobalDocumentDB"; 
                  "locations"=$locations; 
                  "consistencyPolicy"=$consistencyPolicy;}

# Create the database
New-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
                    -ApiVersion "2015-04-08" `
                    -ResourceGroupName $resourceGroupName `
                    -Location $resourceGroupLocation `
                    -Name $DBName `
                    -PropertyObject $DBProperties

# Update failoverpolicy to make West US as a write region
$NewfailoverPolicies = @(@{"locationName"="West US"; "failoverPriority"=0}, @{"locationName"="South Central US"; "failoverPriority"=1}, @{"locationName"="East US"; "failoverPriority"=2} )

Invoke-AzResourceAction `
    -Action failoverPriorityChange `
    -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName `
    -Name $DBName `
    -Parameters @{"failoverPolicies"=$NewfailoverPolicies}


# Add a new locations with priorities
$newLocations = @(@{"locationName"="West US"; 
                 "failoverPriority"=0},
               @{"locationName"="South Central US"; 
                 "failoverPriority"=1},
               @{"locationName"="East US"; 
                 "failoverPriority"=2},
               @{"locationName"="North Central US";
                 "failoverPriority"=3})

# Updated properties
$updateDBProperties = @{"databaseAccountOfferType"="Standard";
                        "locations"=$newLocations;}

# Update the database with the properties
Set-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName $resourceGroupName `
    -Name $DBName `
    -PropertyObject $UpdateDBProperties
