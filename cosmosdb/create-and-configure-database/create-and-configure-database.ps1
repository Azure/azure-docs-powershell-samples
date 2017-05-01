# Set the Azure resource group name and location
$resourceGroupName = "<resource-group-name>"
$resourceGroupLocation = "<resource-group-location>"

# Create the resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation

# Write and read locations and priorities for the database
$locations = @(@{"locationName"="<write-region-location>"; 
                 "failoverPriority"=0}, 
               @{"locationName"="<read-region-location>"; 
                  "failoverPriority"=1})

# IP addresses that can access the database through the firewall
$iprangefilter = "<ip-range-filter>"

# Consistency policy
$consistencyPolicy = @{"defaultConsistencyLevel"="<default-consistency-level>"; 
                       "maxIntervalInSeconds"="<max-interval>"; 
                       "maxStalenessPrefix"="<max-staleness-prefix>"}

# DB properties
$DBProperties = @{"databaseAccountOfferType"="Standard"; 
                          "locations"=$locations; 
                          "consistencyPolicy"=$consistencyPolicy; 
                          "ipRangeFilter"=$iprangefilter}

# Create the database
New-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
                    -ApiVersion "2015-04-08" `
                    -ResourceGroupName $resourceGroupName `
                    -Location $resourceGroupLocation `
                    -Name "<database-account-name>" `
                    -PropertyObject $DBProperties
