$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests', ''
. "$here\$sut"

$clusterName = $ENV:ClusterName
$httpUserPassword = $ENV:HttpPassword
$securePassword = ConvertTo-SecureString $httpUserPassword -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $securePassword


# Mocks don't work for Get-Credential, so we're implementing our own version of it. This is used for tests instead of the real one.
function Get-Credential { return $creds }

Describe "hdinsight-mahout" {
    # Use testdrive since there is a downloaded file
    in $TestDrive {
        It "Runs a MapReduce job using Start-AzHDInsightJob" {
            Mock Read-host { $clusterName }
            # Test that the job succeeded
            (Start-MahoutJob)[0].State | Should be "SUCCEEDED"
        }
        It "Downloaded the output file" {
            Test-Path .\output.txt | Should be True
        }
        It "Downloaded the moviedb file" {
            Test-Path .\moviedb.txt | Should be True
        }
        It "Downloaded the ratings file" {
            Test-Path .\user-ratings.txt | Should be True
        }

        # This isn't a great test, but we don't really know what the
        # Mahout ML will generate as movies in the output. It can be different
        # across different runs and if the data is updated on the cluster.
        It "Displays user-readable output" {
            { Format-MahoutOutput -userId 4 -userDataFile .\user-ratings.txt -movieFile .\moviedb.txt -recommendationFile .\output.txt } | Should not throw
        }
    }
}
