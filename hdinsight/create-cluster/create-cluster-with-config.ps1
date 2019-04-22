function New-ClusterWithConfig {
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

######Start snippet line 59
    $additionalStorageAccountName = Read-Host -Prompt "Enter the name of the additional storage account"

    # Create the additional storage account
    New-AzStorageAccount -ResourceGroupName $resourceGroupName `
        -StorageAccountName $additionalStorageAccountName `
        -Location $location `
        -Type Standard_LRS
    
    # Get the additional storage account key
    $additionalStorageAccountKey = (Get-AzStorageAccountKey -Name $additionalStorageAccountName -ResourceGroupName $resourceGroupName)[0].Value

    # Create a new configuration for RServer cluster type
    # Use -EdgeNodeSize to set the size of the edge node for RServer clusters
    # if you want a specific size. Otherwise, the default size is used.
    $config = New-AzHDInsightClusterConfig `
        -ClusterType "RServer" `
        -EdgeNodeSize "Standard_D12_v2"

    # Add RStudio to the configuration
    $rserverConfig = @{"rstudio"="true"}
    $config = $config | Add-AzHDInsightConfigValues `
        -RServer $rserverConfig `
        -Spark2Defaults $spark2Config

    # Add an additional storage account
    Add-AzHDInsightStorage -Config $config -StorageAccountName "$additionalStorageAccountName.blob.core.windows.net" -StorageAccountKey $additionalStorageAccountKey

    # Create a new HDInsight cluster using -Config
    New-AzHDInsightCluster `
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
######End snippet line 99
}
