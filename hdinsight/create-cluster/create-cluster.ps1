function New-Cluster {
    # Script should stop on failures
    $ErrorActionPreference = "Stop"
######Start snippet line 5
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

    # Create an Az.Storage account and container
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
    $sshCredentials = Get-Credential -Message "Enter SSH user credentials"

    # Default cluster size (# of worker nodes), version, type, and OS
    $clusterSizeInNodes = "4"
    $clusterVersion = "3.6"
    $clusterType = "Hadoop"
    $clusterOS = "Linux"
    # Set the storage container name to the cluster name
    $defaultBlobContainerName = $clusterName

    # Create a blob container. This holds the default data store for the cluster.
    New-AzStorageContainer `
        -Name $clusterName -Context $defaultStorageContext 

    # Create the HDInsight cluster
    New-AzHDInsightCluster `
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
        -DefaultStorageContainer $clusterName `
        -SshCredential $sshCredentials
######End snippet line 71
}
