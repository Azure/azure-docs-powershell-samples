function add-pythonfiles {
    # Script should stop on failures
    $ErrorActionPreference = "Stop"

    # Login to your Azure subscription
    # Is there an active Azure subscription?
    $sub = Get-AzSubscription -ErrorAction SilentlyContinue
    if(-not($sub))
    {
        Connect-AzAccount
    }

    # Revise file path as needed
    $pathToStreamingFile = ".\hiveudf.py"

    # Get cluster info
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"

    $clusterInfo = Get-AzHDInsightCluster -ClusterName $clusterName
    $resourceGroup = $clusterInfo.ResourceGroup
    $storageAccountName=$clusterInfo.DefaultStorageAccount.split('.')[0]
    $container=$clusterInfo.DefaultStorageContainer
    $storageAccountKey=(Get-AzStorageAccountKey `
       -ResourceGroupName $resourceGroup `
       -Name $storageAccountName)[0].Value

    # Create an Azure Storage context
    $context = New-AzStorageContext `
        -StorageAccountName $storageAccountName `
        -StorageAccountKey $storageAccountKey

    # Upload local files to an Azure Storage blob
    Set-AzStorageBlobContent `
        -File $pathToStreamingFile `
        -Blob "hiveudf.py" `
        -Container $container `
        -Context $context
}

function start-hivejob {
    # Script should stop on failures
    $ErrorActionPreference = "Stop"

    # Login to your Azure subscription
    # Is there an active Azure subscription?
    $sub = Get-AzSubscription -ErrorAction SilentlyContinue
    if(-not($sub))
    {
        Connect-AzAccount
    }

    # Get cluster info
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    $creds=Get-Credential -UserName "admin" -Message "Enter the login for the cluster"

    $HiveQuery = "add file wasbs:///hiveudf.py;" +
                    "SELECT TRANSFORM (clientid, devicemake, devicemodel) " +
                    "USING 'python hiveudf.py' AS " +
                    "(clientid string, phoneLabel string, phoneHash string) " +
                    "FROM hivesampletable " +
                    "ORDER BY clientid LIMIT 50;"

    # Create Hive job object
    $jobDefinition = New-AzHDInsightHiveJobDefinition `
        -Query $HiveQuery

    # For status bar updates
    $activity="Hive query"

    # Progress bar (optional)
    Write-Progress -Activity $activity -Status "Starting query..."

    # Start defined Azure HDInsight job on specified cluster.

    $job = Start-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobDefinition $jobDefinition `
        -HttpCredential $creds

    # Progress bar (optional)
    Write-Progress -Activity $activity -Status "Waiting on query to complete..."

    # Wait for completion or failure of specified job
    Wait-AzHDInsightJob `
        -JobId $job.JobId `
        -ClusterName $clusterName `
        -HttpCredential $creds

    # Uncomment the following to see stderr output
    <#
    Get-AzHDInsightJobOutput `
       -Clustername $clusterName `
       -JobId $job.JobId `
       -HttpCredential $creds `
       -DisplayOutputType StandardError
    #>

    # Progress bar (optional)
    Write-Progress -Activity $activity -Status "Retrieving output..."

    # Gets the log output
    Get-AzHDInsightJobOutput `
        -Clustername $clusterName `
        -JobId $job.JobId `
        -HttpCredential $creds
}

function start-pigjob {
    # Script should stop on failures
    $ErrorActionPreference = "Stop"

    # Login to your Azure subscription
    # Is there an active Azure subscription?
    $sub = Get-AzSubscription -ErrorAction SilentlyContinue
    if(-not($sub))
    {
        Connect-AzAccount
    }

    # Get cluster info
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    $creds=Get-Credential -UserName "admin" -Message "Enter the login for the cluster"


    $PigQuery = "Register wasbs:///pigudf.py using jython as myfuncs;" +
                "LOGS = LOAD 'wasbs:///example/data/sample.log' as (LINE:chararray);" +
                "LOG = FILTER LOGS by LINE is not null;" +
                "DETAILS = foreach LOG generate myfuncs.create_structure(LINE);" +
                "DUMP DETAILS;"

    # Create Pig job object
    $jobDefinition = New-AzHDInsightPigJobDefinition -Query $PigQuery

    # For status bar updates
    $activity="Pig job"

    # Progress bar (optional)
    Write-Progress -Activity $activity -Status "Starting job..."


    # Start defined Azure HDInsight job on specified cluster.
    $job = Start-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobDefinition $jobDefinition `
        -HttpCredential $creds

    # Progress bar (optional)
    Write-Progress -Activity $activity -Status "Waiting for the Pig job to complete..."

    # Wait for completion or failure of specified job
    Wait-AzHDInsightJob `
        -Job $job.JobId `
        -ClusterName $clusterName `
        -HttpCredential $creds

    # Uncomment the following to see stderr output
    <#
    Get-AzHDInsightJobOutput `
        -Clustername $clusterName `
        -JobId $job.JobId `
        -HttpCredential $creds `
        -DisplayOutputType StandardError
    #>

    # Progress bar (optional)
    Write-Progress -Activity $activity "Retrieving output..."

    # Gets the log output
    Get-AzHDInsightJobOutput `
        -Clustername $clusterName `
        -JobId $job.JobId `
        -HttpCredential $creds
}

function fix-lineending($original_file) {
    # Set $original_file to the python file path
    $text = [IO.File]::ReadAllText($original_file) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($original_file, $text)
}
