$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests', ''
. "$here\$sut"

$httpUserPassword = $ENV:HttpPassword
$location = $ENV:Location

# Credentials for the cluster
$securePassword = ConvertTo-SecureString $httpUserPassword -AsPlainText -Force
$loginCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $securePassword
$sshCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sshuser", $securePassword

# Can't mock get-credential, so make our own local version
function Get-Credential { 
    Param(
        [string]$Name
    )
    # Return either the admin or ssh credentials
    if($Name -eq "admin") {
        return $loginCreds
    } else {
        return $sshCreds
    }
}

# Random base name for testing
$names="dasher","dancer","prancer","vixen","comet","cupid","donder","blitzen"
$baseName=Get-Random $names
$mills=Get-Date -Format ms
# derived names
$resourceGroupName = $baseName + "rg" + $mills
$clusterName = $baseName + "hdi" + $mills
$storageAccountName = $basename + "store" + $mills

write-host "Creating new resource group named: $resourceGroupName"
Describe "hdinsight-hadoop-customize-cluster-linux" {
    It "Creates a Linux-based cluster with a script action" {
        # Mock data for the various read-hosts in the script
        Mock Read-Host { $resourceGroupName } -ParameterFilter {
            $Prompt -eq "Enter the resource group name"
        }
        Mock Read-Host { $location } -ParameterFilter {
            $Prompt -eq "Enter the Azure region to create resources in"
        }
        Mock Read-Host { $storageAccountName } -ParameterFilter {
            $Prompt -eq "Enter the name of the storage account"
        }
        Mock Read-Host { $clusterName } -ParameterFilter {
            $Prompt -eq "Enter the name of the HDInsight cluster"
        }
        
        # Get the last object returned, which should be the cluster info.
        $clusterInfo = New-HDInsightWithScriptAction
        
        # Then look at the CluterState.
        $clusterInfo[-1].ClusterState | Should be "Running"
        $clusterInfo[-1].Name | Should be $clusterName

        # Verify that the script action was applied
        (get-Azhdinsightscriptactionhistory -ClusterName $clusterName)[0].name | Should be "Install Giraph"
    }

    It "Can run a script action against an existing cluster" {
        Mock Read-Host { $clusterName } -ParameterFilter {
            $Prompt -eq "Enter the name of the HDInsight cluster"
        }
        Mock Read-Host { "Install Solr" } -ParameterFilter {
            "Enter the name of the script action"
        }
        Mock Read-Host { "https://hdiconfigactions.blob.core.windows.net/linuxsolrconfigactionv01/solr-installer-v01.sh" } -ParameterFilter {
            "Enter the URI of the script action"
        }

        (Use-ScriptActionWithCluster)[0].name | Should be "Install Solr"
    }
}

# Delete the resource group to get rid of test artifacts
write-host "Please remember that YOU must manually delete the $resourceGroupName resource group created by this test!!!"
