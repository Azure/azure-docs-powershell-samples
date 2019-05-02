$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests', ''
. "$here\$sut"

$clusterName = $ENV:ClusterName
$httpUserPassword = $ENV:HttpPassword
$securePassword = ConvertTo-SecureString $httpUserPassword -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $securePassword

# Mocks don't work for Get-Credential, so we're implementing our own version of it. This is used for tests instead of the real one.
function Get-Credential { return $creds }

Describe "hdinsight-hadoop-use-pig-powershell" {
    It "Runs a Pig query using Start-AzHDInsightJob" {
        Mock Read-Host { $clusterName }
        # Test that the data we received starts with the expected date column
        (Start-PigJob $clusterName $creds)[-1].StartsWith("(TRACE,816)") | Should be True
    }
}
