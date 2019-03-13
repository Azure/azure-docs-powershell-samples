# Connect-AzAccount
# The SubscriptionId in which to create these objects
$SubscriptionId = ''
# Set the resource group name and location for your managed instance
$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "westus2"
# Set the networking values for your managed instance
$vNetName = "myVnet-$(Get-Random)"
$vNetAddressPrefix = "10.0.0.0/16"
$defaultSubnetName = "myDefaultSubnet-$(Get-Random)"
$defaultSubnetAddressPrefix = "10.0.0.0/24"
$miSubnetName = "myMISubnet-$(Get-Random)"
$miSubnetAddressPrefix = "10.0.0.0/24"
#Set the managed instance name for the new managed instance
$instanceName = "myMIName-$(Get-Random)"
# Set the admin login and password for your managed instance
$miAdminSqlLogin = "SqlAdmin"
$miAdminSqlPassword = "ChangeYourAdminPassword1"
# Set the managed instance service tier, compute level, and license mode
$edition = "General Purpose"
$vCores = 8
$maxStorage = 256
$computeGeneration = "Gen4"
$license = "LicenseIncluded" #"BasePrice" or LicenseIncluded if you have don't have SQL Server licence that can be used for AHB discount

# Set subscription context
Set-AzContext -SubscriptionId $subscriptionId 

# Create a resource group
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

#Configure virtual network, subnets, and routing table
$virtualNetwork = New-AzVirtualNetwork `
                      -ResourceGroupName $resourceGroupName `
                      -Location $location `
                      -Name $vNetName `
                      -AddressPrefix $vNetAddressPrefix

                  Add-AzVirtualNetworkSubnetConfig `
                      -Name $miSubnetName `
                      -VirtualNetwork $virtualNetwork `
                      -AddressPrefix $miSubnetAddressPrefix `
                  | Set-AzVirtualNetwork

$virtualNetwork = Get-AzVirtualNetwork -Name $vNetName -ResourceGroupName $resourceGroupName

$miSubnetConfig = Get-AzVirtualNetworkSubnetConfig `
                        -Name $miSubnetName `
                        -VirtualNetwork $virtualNetwork 

$miSubnetConfigId = $miSubnetConfig.Id

$routeTableMiManagementService = New-AzRouteTable `
                      -Name 'myRouteTableMiManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $location

Set-AzVirtualNetworkSubnetConfig `
                      -VirtualNetwork $virtualNetwork `
                      -Name $miSubnetName `
                      -AddressPrefix $miSubnetAddressPrefix `
                      -RouteTable $routeTableMiManagementService | `
                    Set-AzVirtualNetwork

Get-AzRouteTable `
                      -ResourceGroupName $resourceGroupName `
                      -Name "myRouteTableMiManagementService" `
                      | Add-AzRouteConfig `
                      -Name "ToManagedInstanceManagementService" `
                      -AddressPrefix 0.0.0.0/0 `
                      -NextHopType "Internet" `
                     | Set-AzRouteTable

# Create managed instance in subnet within vNet
New-AzSqlInstance -Name $instanceName `
                      -ResourceGroupName $resourceGroupName -Location westus2 -SubnetId $miSubnetConfigId `
                      -AdministratorCredential (Get-Credential) `
                      -StorageSizeInGB $maxStorage -VCore $vCores -Edition $edition `
                      -ComputeGeneration $computeGeneration -LicenseType $license

# This script will take a minimum of 3 hours to create a new managed instance in a new virtual network. 
# A second managed instance is created much faster.

# Clean up deployment 
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName