<#
.PERMISSIONS REQUIRED
Cluster administrator
.USE CASES
    Run this scripts on any cluster node to update the cluster IPs to the new configuration from the config file path.
.Parameters
$configFilePath - path to the configuration file previously created from the cluster

.NOTES
AUTHOR: Microsoft Services
AUTHOR DATE: 2021-04-23
.CHANGE LOG
#>
param(
[Parameter(Mandatory=$true)]
[string]
$configFilePath)
$resourcelist=Import-Csv -Path $configFilePath

import-module Failoverclusters
$Networks=Get-ClusterNetwork
If ($Networks.Count -gt 1)
{
    $ClusterNetworkName=($Networks | out-gridview -passthru).Name
}
else
{
    $ClusterNetworkName = $Networks.Name 
}
foreach ($resource in $resourcelist)
{
    "Configuring $($resource.ResourceName) with $($resource.NewIP) IP : $($resource.ProbePort) on network $ClusterNetworkName."
    Get-ClusterResource $resource.ResourceName | stop-ClusterResource
    Get-ClusterResource $resource.ResourceName | Set-ClusterParameter -Multiple @{"Address"="$($resource.NewIP)";"ProbePort"=$resource.ProbePort;"SubnetMask"="255.255.255.255";"Network"="$ClusterNetworkName";"EnableDhcp"=0}
    Get-ClusterResource $resource.ResourceName | stop-ClusterResource
    Get-ClusterResource $resource.ResourceName | Set-ClusterParameter -Multiple @{"Address"="$($resource.NewIP)";"ProbePort"=$resource.ProbePort;"SubnetMask"="255.255.255.255";"Network"="$ClusterNetworkName";"EnableDhcp"=0}
    Get-ClusterResource $resource.ResourceName | start-ClusterResource
}
