<#
Due to SQL Managed Instance deployment times, plan for a full day to complete the entire script. 
You can monitor deployment progress in the activity log within the Azure portal.  

For more information on deployment times, see https://learn.microsoft.com/azure/azure-sql/managed-instance/management-operations-overview. 

Closing the session will result in an incomplete deployment. To continue progress, you will
need to determine what the random modifier is and manually replace the random variable with 
the previously-assigned value. 
#>

<#
=============================================================================================
The following sets all the parameters for the two SQL managed instances, and failover group. 
============================================================================================
#>


# Connect-AzAccount
# The SubscriptionId in which to create these objects
$SubscriptionId = ''
# Create a random identifier to use as subscript for the different resource names
$randomIdentifier = $(Get-Random)
# Set the resource group name and location for SQL Managed Instance
$resourceGroupName = "myResourceGroup-$randomIdentifier"
$location = "eastus"
$drLocation = "southcentralus"

# Set the networking values for your primary managed instance
$primaryVNet = "primaryVNet-$randomIdentifier"
$primaryAddressPrefix = "10.0.0.0/16"
$primaryDefaultSubnet = "primaryDefaultSubnet-$randomIdentifier"
$primaryDefaultSubnetAddress = "10.0.0.0/24"
$primaryMiSubnetName = "primaryMISubnet-$randomIdentifier"
$primaryMiSubnetAddress = "10.0.0.0/24"
$primaryMiGwSubnetAddress = "10.0.255.0/27"
$primaryGWName = "primaryGateway-$randomIdentifier"
$primaryGWPublicIPAddress = $primaryGWName + "-ip"
$primaryGWIPConfig = $primaryGWName + "-ipc"
$primaryGWAsn = 61000
$primaryGWConnection = $primaryGWName + "-connection"


# Set the networking values for your secondary managed instance
$secondaryVNet = "secondaryVNet-$randomIdentifier"
$secondaryAddressPrefix = "10.128.0.0/16"
$secondaryDefaultSubnet = "secondaryDefaultSubnet-$randomIdentifier"
$secondaryDefaultSubnetAddress = "10.128.0.0/24"
$secondaryMiSubnetName = "secondaryMISubnet-$randomIdentifier"
$secondaryMiSubnetAddress = "10.128.0.0/24"
$secondaryMiGwSubnetAddress = "10.128.255.0/27"
$secondaryGWName = "secondaryGateway-$randomIdentifier"
$secondaryGWPublicIPAddress = $secondaryGWName + "-IP"
$secondaryGWIPConfig = $secondaryGWName + "-ipc"
$secondaryGWAsn = 62000
$secondaryGWConnection = $secondaryGWName + "-connection"



# Set the SQL Managed Instance name for the new managed instances
$primaryInstance = "primary-mi-$randomIdentifier"
$secondaryInstance = "secondary-mi-$randomIdentifier"

# Set the admin login and password for SQL Managed Instance
$secpasswd = "PWD27!"+(New-Guid).Guid | ConvertTo-SecureString -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("azureuser", $secpasswd)


# Set the SQL Managed Instance service tier, compute level, and license mode
$edition = "General Purpose"
$vCores = 8
$maxStorage = 256
$computeGeneration = "Gen5"
$license = "LicenseIncluded" #"BasePrice" or LicenseIncluded if you have don't have SQL Server license that can be used for AHB discount

# Set failover group details
$vpnSharedKey = "mi1mi2psk"
$failoverGroupName = "failovergroup-$randomIdentifier"

# Show randomized variables
Write-host "Resource group name is" $resourceGroupName
Write-host "Password is" $secpasswd
Write-host "Primary Virtual Network name is" $primaryVNet
Write-host "Primary default subnet name is" $primaryDefaultSubnet
Write-host "Primary SQL Managed Instance subnet name is" $primaryMiSubnetName
Write-host "Secondary Virtual Network name is" $secondaryVNet
Write-host "Secondary default subnet name is" $secondaryDefaultSubnet
Write-host "Secondary SQL Managed Instance subnet name is" $secondaryMiSubnetName
Write-host "Primary SQL Managed Instance name is" $primaryInstance
Write-host "Secondary SQL Managed Instance name is" $secondaryInstance
Write-host "Failover group name is" $failoverGroupName

<#===========================================================================
The following sets your subscription context and creates the resource group
==========================================================================#>


# Suppress networking breaking changes warning (https://aka.ms/azps-changewarnings
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

# Set the subscription context
Set-AzContext -SubscriptionId $subscriptionId 

# Create the resource group
Write-host "Creating resource group..."
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag @{Owner="SQLDB-Samples"}
$resourceGroup

<#===========================================================================
The following configures resources for the primary SQL Managed Instance
===========================================================================#>


# Configure the primary virtual network
Write-host "Creating primary virtual network..."
$primarySubnetDelegation = New-AzDelegation -Name "ManagedInstance" -ServiceName "Microsoft.Sql/managedInstances"
$primaryVirtualNetwork = New-AzVirtualNetwork `
                      -ResourceGroupName $resourceGroupName `
                      -Location $location `
                      -Name $primaryVNet `
                      -AddressPrefix $primaryAddressPrefix
Add-AzVirtualNetworkSubnetConfig `
                      -Name $primaryMiSubnetName `
                      -VirtualNetwork $primaryVirtualNetwork `
                      -AddressPrefix $PrimaryMiSubnetAddress `
                      -Delegation $primarySubnetDelegation `
                    | Set-AzVirtualNetwork
$primaryVirtualNetwork
Write-host "Primary virtual network created successfully."


# Configure the primary managed instance subnet
Write-host "Configuring primary MI subnet..."
$primaryVirtualNetwork = Get-AzVirtualNetwork -Name $primaryVNet -ResourceGroupName $resourceGroupName


$primaryMiSubnetConfig = Get-AzVirtualNetworkSubnetConfig `
                        -Name $primaryMiSubnetName `
                        -VirtualNetwork $primaryVirtualNetwork
$primaryMiSubnetConfig
Write-host "Primary MI subnet configured successfully."


# Configure the network security group management service
Write-host "Configuring primary MI network security group..."

$primaryMiSubnetConfigId = $primaryMiSubnetConfig.Id

$primaryNSGMiManagementService = New-AzNetworkSecurityGroup `
                      -Name 'primaryNSGMiManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $location
$primaryNSGMiManagementService
Write-host "Primary MI network security group configured successfully."


# Configure the route table management service
Write-host "Configuring primary MI route table management service..."

$primaryRouteTableMiManagementService = New-AzRouteTable `
                      -Name 'primaryRouteTableMiManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $location
$primaryRouteTableMiManagementService
Write-host "Primary MI route table management service configured successfully."


# Configure the primary network security group
Write-host "Configuring primary network security group..."
Set-AzVirtualNetworkSubnetConfig `
                      -VirtualNetwork $primaryVirtualNetwork `
                      -Name $primaryMiSubnetName `
                      -AddressPrefix $PrimaryMiSubnetAddress `
                      -NetworkSecurityGroup $primaryNSGMiManagementService `
                      -RouteTable $primaryRouteTableMiManagementService `
                      -Delegation $primarySubnetDelegation `
                    | Set-AzVirtualNetwork

Get-AzNetworkSecurityGroup `
                      -ResourceGroupName $resourceGroupName `
                      -Name "primaryNSGMiManagementService" `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name "allow_management_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange 9000,9003,1438,1440,1452 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix $PrimaryMiSubnetAddress `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 300 `
                      -Name "allow_health_probe_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix AzureLoadBalancer `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1000 `
                      -Name "allow_tds_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 1433 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1100 `
                      -Name "allow_redirect_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 11000-11999 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1200 `
                      -Name "allow_geodr_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 5022 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_inbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name "allow_management_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange 80,443,12000 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_outbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix $PrimaryMiSubnetAddress `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1100 `
                      -Name "allow_redirect_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 11000-11999 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1200 `
                      -Name "allow_geodr_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 5022 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_outbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Set-AzNetworkSecurityGroup
Write-host "Primary network security group configured successfully."

#  Configure the primary network route table
Write-host "Configuring primary network route table..."
Get-AzRouteTable `
                      -ResourceGroupName $resourceGroupName `
                      -Name "primaryRouteTableMiManagementService" `
                    | Add-AzRouteConfig `
                      -Name "primaryToMIManagementService" `
                      -AddressPrefix 0.0.0.0/0 `
                      -NextHopType Internet `
                    | Add-AzRouteConfig `
                      -Name "ToLocalClusterNode" `
                      -AddressPrefix $PrimaryMiSubnetAddress `
                      -NextHopType VnetLocal `
                    | Set-AzRouteTable
Write-host "Primary network route table configured successfully."


# Create the primary managed instance
Write-host "Creating primary SQL Managed Instance..."
Write-host "This will take some time, see https://learn.microsoft.com/azure/azure-sql/managed-instance/management-operations-overview for more information."
New-AzSqlInstance -Name $primaryInstance `
                      -ResourceGroupName $resourceGroupName `
                      -Location $location `
                      -SubnetId $primaryMiSubnetConfigId `
                      -AdministratorCredential $mycreds `
                      -StorageSizeInGB $maxStorage `
                      -VCore $vCores `
                      -Edition $edition `
                      -ComputeGeneration $computeGeneration `
                      -LicenseType $license
$primaryInstance
Write-host "Primary SQL Managed Instance created successfully."

<#===========================================================================
The following configures resources for the secondary SQL Managed Instance
===========================================================================#>

# Configure the secondary virtual network 
Write-host "Configuring secondary virtual network..."
$secondarySubnetDelegation = New-AzDelegation -Name "ManagedInstance" -ServiceName "Microsoft.Sql/managedInstances"
$SecondaryVirtualNetwork = New-AzVirtualNetwork `
                      -ResourceGroupName $resourceGroupName `
                      -Location $drlocation `
                      -Name $secondaryVNet `
                      -AddressPrefix $secondaryAddressPrefix
Add-AzVirtualNetworkSubnetConfig `
                      -Name $secondaryMiSubnetName `
                      -VirtualNetwork $SecondaryVirtualNetwork `
                      -AddressPrefix $secondaryMiSubnetAddress `
                      -Delegation $secondarySubnetDelegation `
                    | Set-AzVirtualNetwork
$SecondaryVirtualNetwork
Write-host "Secondary virtual network configured successfully."


# Configure the secondary managed instance subnet
Write-host "Configuring secondary MI subnet..."

$SecondaryVirtualNetwork = Get-AzVirtualNetwork -Name $secondaryVNet `
                                -ResourceGroupName $resourceGroupName

$secondaryMiSubnetConfig = Get-AzVirtualNetworkSubnetConfig `
                        -Name $secondaryMiSubnetName `
                        -VirtualNetwork $SecondaryVirtualNetwork
$secondaryMiSubnetConfig
Write-host "Secondary MI subnet configured successfully."


# Configure the secondary network security group management service
Write-host "Configuring secondary network security group management service..."

$secondaryMiSubnetConfigId = $secondaryMiSubnetConfig.Id

$secondaryNSGMiManagementService = New-AzNetworkSecurityGroup `
                      -Name 'secondaryToMIManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $drlocation
$secondaryNSGMiManagementService
Write-host "Secondary network security group management service configured successfully."


# Configure the secondary route table MI management service
Write-host "Configuring secondary route table MI management service..."

$secondaryRouteTableMiManagementService = New-AzRouteTable `
                      -Name 'secondaryRouteTableMiManagementService' `
                      -ResourceGroupName $resourceGroupName `
                      -location $drlocation
$secondaryRouteTableMiManagementService
Write-host "Secondary route table MI management service configured successfully."


# Configure the secondary network security group
Write-host "Configuring secondary network security group..."

Set-AzVirtualNetworkSubnetConfig `
                      -VirtualNetwork $SecondaryVirtualNetwork `
                      -Name $secondaryMiSubnetName `
                      -AddressPrefix $secondaryMiSubnetAddress `
                      -NetworkSecurityGroup $secondaryNSGMiManagementService `
                      -RouteTable $secondaryRouteTableMiManagementService `
                      -Delegation $secondarySubnetDelegation `
                    | Set-AzVirtualNetwork

Get-AzNetworkSecurityGroup `
                      -ResourceGroupName $resourceGroupName `
                      -Name "secondaryToMIManagementService" `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name "allow_management_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange 9000,9003,1438,1440,1452 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix $secondaryMiSubnetAddress `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 300 `
                      -Name "allow_health_probe_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix AzureLoadBalancer `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1000 `
                      -Name "allow_tds_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 1433 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1100 `
                      -Name "allow_redirect_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 11000-11999 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1200 `
                      -Name "allow_geodr_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 5022 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_inbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name "allow_management_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange 80,443,12000 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_outbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix $secondaryMiSubnetAddress `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1100 `
                      -Name "allow_redirect_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 11000-11999 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 1200 `
                      -Name "allow_geodr_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 5022 `
                      -DestinationAddressPrefix * `
                    | Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_outbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
                    | Set-AzNetworkSecurityGroup
Write-host "Secondary network security group configured successfully."

#  Configure the secondarynetwork route table
Write-host "Configuring secondary network route table..."
Get-AzRouteTable `
                      -ResourceGroupName $resourceGroupName `
                      -Name "secondaryRouteTableMiManagementService" `
                    | Add-AzRouteConfig `
                      -Name "secondaryToMIManagementService" `
                      -AddressPrefix 0.0.0.0/0 `
                      -NextHopType Internet `
                    | Add-AzRouteConfig `
                      -Name "ToLocalClusterNode" `
                      -AddressPrefix $secondaryMiSubnetAddress `
                      -NextHopType VnetLocal `
                    | Set-AzRouteTable
Write-host "Secondary network route table configured successfully."


# Create the secondary managed instance
$primaryManagedInstanceId = Get-AzSqlInstance -Name $primaryInstance -ResourceGroupName $resourceGroupName | Select-Object Id


Write-host "Creating secondary SQL Managed Instance..."
Write-host "This will take some time, see https://learn.microsoft.com/azure/azure-sql/managed-instance/management-operations-overview for more information."
New-AzSqlInstance -Name $secondaryInstance `
                  -ResourceGroupName $resourceGroupName `
                  -Location $drLocation `
                  -SubnetId $secondaryMiSubnetConfigId `
                  -AdministratorCredential $mycreds `
                  -StorageSizeInGB $maxStorage `
                  -VCore $vCores `
                  -Edition $edition `
                  -ComputeGeneration $computeGeneration `
                  -LicenseType $license `
                  -DnsZonePartner $primaryManagedInstanceId.Id
Write-host "Secondary SQL Managed Instance created successfully."


<#===========================================================================
The following configures the failover group
===========================================================================#>


# Create global virtual network peering
$primaryVirtualNetwork  = Get-AzVirtualNetwork `
                  -Name $primaryVNet `
                  -ResourceGroupName $resourceGroupName

$secondaryVirtualNetwork = Get-AzVirtualNetwork `
                  -Name $secondaryVNet `
                  -ResourceGroupName $resourceGroupName
                  
Write-host "Peering primary VNet to secondary VNet..."
Add-AzVirtualNetworkPeering `
 -Name primaryVnet-secondaryVNet1 `
 -VirtualNetwork $primaryVirtualNetwork `
 -RemoteVirtualNetworkId $secondaryVirtualNetwork.Id
 Write-host "Primary VNet peered to secondary VNet successfully."

Write-host "Peering secondary VNet to primary VNet..."
Add-AzVirtualNetworkPeering `
 -Name secondaryVNet-primaryVNet `
 -VirtualNetwork $secondaryVirtualNetwork `
 -RemoteVirtualNetworkId $primaryVirtualNetwork.Id
Write-host "Secondary VNet peered to primary VNet successfully."

Write-host "Checking peering state on the primary virtual network..."
Get-AzVirtualNetworkPeering `
-ResourceGroupName $resourceGroupName `
-VirtualNetworkName $primaryVNet `
| Select PeeringState

Write-host "Checking peering state on the secondary virtual network..."
Get-AzVirtualNetworkPeering `
-ResourceGroupName $resourceGroupName `
-VirtualNetworkName $secondaryVNet `
| Select PeeringState

# Create failover group
Write-host "Creating the failover group..."
$failoverGroup = New-AzSqlDatabaseInstanceFailoverGroup -Name $failoverGroupName `
     -Location $location -ResourceGroupName $resourceGroupName -PrimaryManagedInstanceName $primaryInstance `
     -PartnerRegion $drLocation -PartnerManagedInstanceName $secondaryInstance `
     -FailoverPolicy Automatic -GracePeriodWithDataLossHours 1
$failoverGroup

# Verify the current primary role
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $location -Name $failoverGroupName

# Failover the primary managed instance to the secondary role
Write-host "Failing primary over to the secondary location"
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $drLocation -Name $failoverGroupName | Switch-AzSqlDatabaseInstanceFailoverGroup
Write-host "Successfully failed failover group to secondary location"

# Verify the current primary role
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $drLocation -Name $failoverGroupName

# Fail primary managed instance back to primary role
Write-host "Failing primary back to primary role"
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $location -Name $failoverGroupName | Switch-AzSqlDatabaseInstanceFailoverGroup
Write-host "Successfully failed failover group to primary location"

# Verify the current primary role
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $location -Name $failoverGroupName



# Clean up deployment 
<# You will need to remove the resource group twice. Removing the resource group the first time will remove the managed instance and virtual clusters but will then fail with the error message `Remove-AzResourceGroup : Long running operation failed with status 'Conflict'.`. Run the Remove-AzResourceGroup command a second time to remove any residual resources as well as the resource group. #> 

# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName
# Write-host "Removing managed instance and virtual cluster..."
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName
# Write-host "Removing residual resources and resource group..."


# Show randomized variables
Write-host "Resource group name is" $resourceGroupName
Write-host "Password is" $secpasswd
Write-host "Primary Virtual Network name is" $primaryVNet
Write-host "Primary default subnet name is" $primaryDefaultSubnet
Write-host "Primary managed instance subnet name is" $primaryMiSubnetName
Write-host "Secondary Virtual Network name is" $secondaryVNet
Write-host "Secondary default subnet name is" $secondaryDefaultSubnet
Write-host "Secondary managed instance subnet name is" $secondaryMiSubnetName
Write-host "Primary managed instance name is" $primaryInstance
Write-host "Secondary managed instance name is" $secondaryInstance
Write-host "Failover group name is" $failoverGroupName

