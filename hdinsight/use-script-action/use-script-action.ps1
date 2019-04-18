function new-hdinsightwithscriptaction {
    # Script should stop on failures
    $ErrorActionPreference = "Stop"

    # Login to your Azure subscription
    $context = Get-AzContext
    if ($context -eq $null) 
    {
        Connect-AzAccount
    }
    $context

    # If you have multiple subscriptions, set the one to use
    # $subscriptionID = "<subscription ID to use>"
    # Select-AzSubscription -SubscriptionId $subscriptionID

    # Get user input/default values
    $resourceGroupName = Read-Host -Prompt "Enter the resource group name"
    $location = Read-Host -Prompt "Enter the Azure region to create resources in"

    # Create the resource group
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    $defaultStorageAccountName = Read-Host -Prompt "Enter the name of the storage account"

    # Create an Azure storae account and container
    New-AzStorageAccount `
        -ResourceGroupName $resourceGroupName `
        -Name $defaultStorageAccountName `
        -Type Standard_LRS `
        -Location $location
    $defaultStorageAccountKey = (Get-AzStorageAccountKey `
                                    -ResourceGroupName $resourceGroupName `
                                    -Name $defaultStorageAccountName)[0].Value
    $defaultStorageContext = New-AzStorageContext `
                                    -StorageAccountName $defaultStorageAccountName `
                                    -StorageAccountKey $defaultStorageAccountKey

    # Get information for the HDInsight cluster
    $clusterName = Read-Host -Prompt "Enter the name of the HDInsight cluster"
    # Cluster login is used to secure HTTPS services hosted on the cluster
    $httpCredential = Get-Credential -Message "Enter Cluster login credentials" -UserName "admin"
    # SSH user is used to remotely connect to the cluster using SSH clients
    $sshCredential = Get-Credential -Message "Enter SSH user credentials"

    # Default cluster size (# of worker nodes), version, type, and OS
    $clusterSizeInNodes = "4"
    $clusterVersion = "3.5"
    $clusterType = "Hadoop"
    $clusterOS = "Linux"
    # Set the storage container name to the cluster name
    $defaultBlobContainerName = $clusterName

    # Create a blob container. This holds the default data store for the cluster.
    New-AzStorageContainer `
        -Name $clusterName -Context $defaultStorageContext

    # Create an HDInsight configuration object
    $config = New-AzHDInsightClusterConfig
    # Add the script action
    $scriptActionUri="https://hdiconfigactions.blob.core.windows.net/linuxgiraphconfigactionv01/giraph-installer-v01.sh"
    # Add for the head nodes
    $config = Add-AzHDInsightScriptAction `
        -Config $config `
        -Name "Install Giraph" `
        -NodeType HeadNode `
        -Uri $scriptActionUri
    # Continue adding the script action for any other node types
    # that it must run on.
    $config = Add-AzHDInsightScriptAction `
        -Config $config `
        -Name "Install Giraph" `
        -NodeType WorkerNode `
        -Uri $scriptActionUri

    # Create the cluster using the configuration object
    New-AzHDInsightCluster `
        -Config $config `
        -ResourceGroupName $resourceGroupName `
        -ClusterName $clusterName `
        -Location $location `
        -ClusterSizeInNodes $clusterSizeInNodes `
        -ClusterType $clusterType `
        -OSType $clusterOS `
        -Version $clusterVersion `
        -HttpCredential $httpCredential `
        -DefaultStorageAccountName "$defaultStorageAccountName.blob.core.windows.net" `
        -DefaultStorageAccountKey $defaultStorageAccountKey `
        -DefaultStorageContainer $containerName `
        -SshCredential $sshCredential
}

function use-scriptactionwithcluster {
        # Script should stop on failures
    $ErrorActionPreference = "Stop"

    # Login to your Azure subscription
    $context = Get-AzContext
    if ($context -eq $null) 
    {
        Connect-AzAccount
    }
    $context

    # Get information for the HDInsight cluster
    $clusterName = Read-Host -Prompt "Enter the name of the HDInsight cluster"
    $scriptActionName = Read-Host -Prompt "Enter the name of the script action"
    $scriptActionUri = Read-Host -Prompt "Enter the URI of the script action"
    # The node types that the script action is applied to
    $nodeTypes = "headnode", "workernode"

    # Apply the script and mark as persistent
    Submit-AzHDInsightScriptAction -ClusterName $clusterName `
        -Name $scriptActionName `
        -Uri $scriptActionUri `
        -NodeTypes $nodeTypes `
        -PersistOnSuccess
}

# WARNING: this script does NOT have tests. It is just here so
# that we can pull it in to the docs. It has dummy values.
function get-scriptactionhistory {
    # Get a history of scripts
    Get-AzHDInsightScriptActionHistory -ClusterName mycluster

    # From the list, we want to get information on a specific script
    Get-AzHDInsightScriptActionHistory -ClusterName mycluster `
        -ScriptExecutionId 635920937765978529

    # Promote this to a persisted script
    # Note: the script must have a unique name to be promoted
    # if the name is not unique, you receive an error
    Set-AzHDInsightPersistedScriptAction -ClusterName mycluster `
        -ScriptExecutionId 635920937765978529

    # Demote the script back to ad hoc
    # Note that demotion uses the unique script name instead of
    # execution ID.
    Remove-AzHDInsightPersistedScriptAction -ClusterName mycluster `
        -Name "Install Giraph"
}