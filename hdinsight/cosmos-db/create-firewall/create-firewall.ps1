# Retrieve the current database information
$DB = Get-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName "<resource-group-name>" `
    -Name "<database-account-name>"

# Retrieve the properties
$DBProperties = $DB.Properties
# Update the IP addresses allowed through the firewall
$DBProperties.ipRangeFilter = "<ip-range-filter>"

# Update the database with the properties
Set-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" `
    -ResourceGroupName "<resource-group-name>" `
    -Name "<database-account-name>" `
    -PropertyObject $DBProperties
