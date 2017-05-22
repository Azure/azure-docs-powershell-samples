function New-ClusterWithZeppelin {
    # Script should stop on failures
    $ErrorActionPreference = "Stop"

    # Login to your Azure subscription
    # Is there an active Azure subscription?
    $sub = Get-AzureRmSubscription -ErrorAction SilentlyContinue
    if(-not($sub))
    {
        Add-AzureRmAccount
    }

    # If you have multiple subscriptions, set the one to use
    # $subscriptionID = "<subscription ID to use>"
    # Select-AzureRmSubscription -SubscriptionId $subscriptionID

    # Get user input/default values
    $resourceGroupName = Read-Host -Prompt "Enter the resource group name"
    $location = Read-Host -Prompt "Enter the Azure region to create resources in"

    # Create the resource group
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

    $defaultStorageAccountName = Read-Host -Prompt "Enter the name of the storage account"

    # Create an Azure storae account and container
    New-AzureRmStorageAccount `
        -ResourceGroupName $resourceGroupName `
        -Name $defaultStorageAccountName `
        -Type Standard_LRS `
        -Location $location
    $defaultStorageAccountKey = (Get-AzureRmStorageAccountKey `
                                    -ResourceGroupName $resourceGroupName `
                                    -Name $defaultStorageAccountName)[0].Value
    $defaultStorageContext = New-AzureStorageContext `
                                    -StorageAccountName $defaultStorageAccountName `
                                    -StorageAccountKey $defaultStorageAccountKey

    # Get information for the HDInsight cluster
    $clusterName = Read-Host -Prompt "Enter the name of the HDInsight cluster"
    # Cluster login is used to secure HTTPS services hosted on the cluster
    $httpCredential = Get-Credential -Message "Enter Cluster login credentials" -UserName "admin"
    # SSH user is used to remotely connect to the cluster using SSH clients
    $sshCredentials = Get-Credential -Message "Enter SSH user credentials"

    # Default cluster size (# of worker nodes), version, type, and OS
    $clusterSizeInNodes = "4"
    $clusterVersion = "3.5"
    $clusterType = "Spark"
    $clusterOS = "Linux"
    # Set the storage container name to the cluster name
    $defaultBlobContainerName = $clusterName

    # Create a blob container. This holds the default data store for the cluster.
    New-AzureStorageContainer `
        -Name $clusterName -Context $defaultStorageContext

######Start snippet line 59
    # Create a new configuration object
    $config = New-AzureRmHDInsightClusterConfig `
        -ClusterType $clusterType `

    # Add Zeppelin script action
    Add-AzureRMHDInsightScriptAction -Config $config `
        -Name "Install Zeppelin" `
        -NodeType HeadNode `
        -Parameters "void" `
        -Uri "https://hdiconfigactions.blob.core.windows.net/linuxincubatorzeppelinv01/install-zeppelin-spark151-v01.sh"

    # Create a new HDInsight cluster using -Config
    New-AzureRmHDInsightCluster `
        -ClusterName $clusterName `
        -ResourceGroupName $resourceGroupName `
        -HttpCredential $httpCredential `
        -Location $location `
        -DefaultStorageAccountName "$defaultStorageAccountName.blob.core.windows.net" `
        -DefaultStorageAccountKey $defaultStorageAccountKey `
        -DefaultStorageContainer $defaultStorageContainerName  `
        -ClusterSizeInNodes $clusterSizeInNodes `
        -OSType $clusterOS `
        -Version $clusterVersion `
        -SshCredential $sshCredentials `
        -Config $config
######End snippet line 84
}