#Run this script to gather cluster roles` information.
#No parameters required. Script needs to be run on any cluster node.
$clusterOutputFile="cluster-config.csv"
$groups=Get-ClusterGroup
"RoleName,ResourceName,IP,ProbePort,ServicePort,NewIP" | out-file $clusterOutputFile
$probePort=59999 # initial probe port number.
foreach ($g in $groups)
{
    $resources=$g | Get-ClusterResource | Where-Object {$_.ResourceType -eq 'IP Address'}
    foreach ($r in $resources)
    {
        $params=$r | Get-ClusterParameter | Where-Object {$_.Name -eq "Address"}
        "$($g.name),$($r.Name),$($params.Value),$probePort,," | out-file $clusterOutputFile -append
        $probePort++
    }
}
