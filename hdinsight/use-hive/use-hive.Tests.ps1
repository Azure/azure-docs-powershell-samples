$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests', ''
. "$here\$sut"

$clusterName = $ENV:ClusterName
$httpUserPassword = $ENV:HttpPassword
$securePassword = ConvertTo-SecureString $httpUserPassword -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $securePassword

# Mocks don't work for Get-Credential, so we're implementing our own version of it. This is used for tests instead of the real one.
function Get-Credential { return $creds }

Describe "hdinsight-hadoop-use-hive-powershell" {
    It "Runs a Hive query using Start-AzHDInsightJob" {
        # Since we only read-host to get the cluster name for this script,
        # just return it
        Mock Read-Host { $clusterName }
        
        # Test that the data we received starts with the expected date column
        (Start-HiveJob)[-1].StartsWith("2012-02-03") | Should be True
    }

    It "Runs a Hive query using Invoke-Hive" {
        # Since we only read-host to get the cluster name for this script,
        # just return it
        Mock Read-Host { $clusterName }
        
        # Test that the data we receive starts with the expected date column
        (Start-HiveJobInvoke)[-1].StartsWith("2012-02-03") | Should be True
    }

}
