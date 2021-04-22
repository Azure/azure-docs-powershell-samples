<#
.PERMISSIONS REQUIRED
Contributor
.USE CASES

.Parameters
$configFilePath - path to the configuration file previously created from the cluster
$ResourceGroupName - resource group containing VM with cluster disks
clusterName - to be used as prefix for the shared disks
numberOfNodes - used to determined the minimum azure disk size and max shares for the disks
startindDiskNumber - initial number to be added to the shared disk names.
VnetName - name of the VNet for the load balancer
subnetName - name of the subnet for the load balancer
VnetResourceGroupName - name of the resource group containing the VNet
Location - Azure region
LoadBalancerName - name of the load balancer resource
LoadBalancerSKU - Basic or Standard. Standard is default.

.NOTES
AUTHOR: Microsoft Services (Jose Fehse)
AUTHOR DATE: 2021-04-23
.CHANGE LOG
#>
param(
[Parameter(Mandatory=$true)]
[string]
$configFilePath,
[Parameter(Mandatory=$true)]
[string]
$ResourceGroupName, #resource group to create the load balancer
[Parameter(Mandatory=$true)]
[string]
$VnetName,
[Parameter(Mandatory=$true)]
[string]
$subnetName,
[Parameter(Mandatory=$true)]
[string]
$VnetResourceGroupName,
[Parameter(Mandatory=$true)]
[string]
$Location,
[Parameter(Mandatory=$true)]
[string]
$LoadBalancerName,
[Parameter(Mandatory=$false)]
[string]
$LoadBalancerSKU="Standard"
)
if ($vnetRG -eq "" -or $null -eq $vnetRG)
{
    $vnetRG=$ResourceGroupName
}
$LBBackEndName="ClusterBackendPool"
try {
    $configParameters=Import-Csv -Path $configFilePath
}
catch {
    Write-Error "Error reading config file $configfilepath ."
    break
}
$subnetId=((Get-AzVirtualNetwork -ResourceGroupName $VnetResourceGroupName -Name $vnetName).Subnets | Where-Object {$_.Name -eq $subnetName}).Id
if (!(Get-AzLoadBalancer -Name $LoadBalancerName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue))
{
    "Creating LB"
    $newLB = New-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name $LoadBalancerName -Location $location -BackendAddressPool (New-AzLoadBalancerBackendAddressPoolConfig -Name  $LBBackEndName) `
    -FrontendIpConfiguration (New-AzLoadBalancerFrontendIpConfig -Name "Frontendconfig" -SubnetId $subnetId ) -Sku $LoadBalancerSKU
}
else {
    "Using existing LB."
    $newLB=Get-AzLoadBalancer -Name $LoadBalancerName -ResourceGroupName $ResourceGroupName
}
foreach ($configitem in $configParameters)
{
    $roleName=$configitem.RoleName.Replace(" ","_")
    Write-Output "Creating load balancer configuration for $rolename (IP, probe and rule)."
    Add-AzLoadBalancerFrontendIpConfig -Name "$roleName-IP" -PrivateIpAddress $configItem.NewIP -SubnetId $subnetId -LoadBalancer $newLb | Set-AzLoadBalancer
    Add-AzLoadBalancerProbeConfig -Name "$roleName-Probe" -Protocol TCP -Port $configItem.ProbePort -IntervalInSeconds 15 -ProbeCount 2 -LoadBalancer $newLb | Set-AzLoadBalancer
    Add-AzLoadBalancerRuleConfig -Name "$roleName-Rule" -ProbeId ($newLB.Probes | Where-Object {$_.Name -eq "$roleName-Probe"}).Id `
    -LoadBalancer $newLB -Protocol "tcp" -FrontendPort $configItem.ServicePort `
    -BackendPort $configItem.ServicePort -EnableFloatingIP  -FrontendIpConfigurationId ($newLB.FrontendIpConfigurations | Where-Object {$_.PrivateIpAddress -eq $configitem.NewIP}).Id `
    -BackendAddressPoolId ($newLB.BackendAddressPools[0].Id) | Set-AzLoadBalancer
}
Remove-AzLoadBalancerFrontendIpConfig -Name "Frontendconfig" -LoadBalancer $newLB | Set-AzLoadBalancer
