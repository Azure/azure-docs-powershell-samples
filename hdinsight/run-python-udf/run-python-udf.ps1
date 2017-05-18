function add-pythonfiles {
    # Script should stop on failures
    $ErrorActionPreference = "Stop"

    # Login to your Azure subscription
    # Is there an active Azure subscription?
    $sub = Get-AzureRmSubscription -ErrorAction SilentlyContinue
    if(-not($sub))
    {
        Add-AzureRmAccount
    }

    # Get cluster info
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    $pathToStreamingFile = ".\streaming.py"
    $pathToJythonFile = ".\pig_python.py"

    $clusterInfo = Get-AzureRmHDInsightCluster -ClusterName $clusterName
    $resourceGroup = $clusterInfo.ResourceGroup
    $storageAccountName=$clusterInfo.DefaultStorageAccount.split('.')[0]
    $container=$clusterInfo.DefaultStorageContainer
    $storageAccountKey=(Get-AzureRmStorageAccountKey `
        -Name $storageAccountName `
    -ResourceGroupName $resourceGroup)[0].Value

    #Create a storage content and upload the file
    $context = New-AzureStorageContext `
        -StorageAccountName $storageAccountName `
        -StorageAccountKey $storageAccountKey

    Set-AzureStorageBlobContent `
        -File $pathToStreamingFile `
        -Blob "streaming.py" `
        -Container $container `
        -Context $context

    Set-AzureStorageBlobContent `
        -File $pathToJythonFile `
        -Blob "pig_python.py" `
        -Container $container `
        -Context $context
}

function start-hivejob {
    # Script should stop on failures
    $ErrorActionPreference = "Stop"

    # Login to your Azure subscription
    # Is there an active Azure subscription?
    $sub = Get-AzureRmSubscription -ErrorAction SilentlyContinue
    if(-not($sub))
    {
        Add-AzureRmAccount
    }

    # Get cluster info
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    $creds=Get-Credential -UserName "admin" -Message "Enter the login for the cluster"

    # If using a Windows-based HDInsight cluster, change the USING statement to:
    # "USING 'D:\Python27\python.exe streaming.py' AS " +
    $HiveQuery = "add file wasbs:///streaming.py;" +
                    "SELECT TRANSFORM (clientid, devicemake, devicemodel) " +
                    "USING 'python streaming.py' AS " +
                    "(clientid string, phoneLabel string, phoneHash string) " +
                    "FROM hivesampletable " +
                    "ORDER BY clientid LIMIT 50;"

    $jobDefinition = New-AzureRmHDInsightHiveJobDefinition `
        -Query $HiveQuery
    
    # For status bar updates
    $activity="Hive query"
    Write-Progress -Activity $activity -Status "Starting query..."
    $job = Start-AzureRmHDInsightJob `
        -ClusterName $clusterName `
        -JobDefinition $jobDefinition `
        -HttpCredential $creds
    Write-Progress -Activity $activity -Status "Waiting on query to complete..."
    Wait-AzureRmHDInsightJob `
        -JobId $job.JobId `
        -ClusterName $clusterName `
        -HttpCredential $creds
    # Uncomment the following to see stderr output
    # Get-AzureRmHDInsightJobOutput `
    #   -Clustername $clusterName `
    #   -JobId $job.JobId `
    #   -HttpCredential $creds `
    #   -DisplayOutputType StandardError
    Write-Progress -Activity $activity -Status "Retrieving output..."
    Get-AzureRmHDInsightJobOutput `
        -Clustername $clusterName `
        -JobId $job.JobId `
        -HttpCredential $creds
}

function start-pigjob {
    # Script should stop on failures
    $ErrorActionPreference = "Stop"

    # Login to your Azure subscription
    # Is there an active Azure subscription?
    $sub = Get-AzureRmSubscription -ErrorAction SilentlyContinue
    if(-not($sub))
    {
        Add-AzureRmAccount
    }

    # Get cluster info
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    $creds=Get-Credential -UserName "admin" -Message "Enter the login for the cluster"

    $PigQuery = "Register wasbs:///pig_python.py using jython as myfuncs;" +
                "LOGS = LOAD 'wasbs:///example/data/sample.log' as (LINE:chararray);" +
                "LOG = FILTER LOGS by LINE is not null;" +
                "DETAILS = foreach LOG generate myfuncs.create_structure(LINE);" +
                "DUMP DETAILS;"

    $jobDefinition = New-AzureRmHDInsightPigJobDefinition -Query $PigQuery

    # For status bar updates
    $activity="Pig job"
    Write-Progress -Activity $activity -Status "Starting job..."
    $job = Start-AzureRmHDInsightJob `
        -ClusterName $clusterName `
        -JobDefinition $jobDefinition `
        -HttpCredential $creds

    Write-Progress -Activity $activity -Status "Waiting for the Pig job to complete..."
    Wait-AzureRmHDInsightJob `
        -Job $job.JobId `
        -ClusterName $clusterName `
        -HttpCredential $creds
    # Uncomment the following to see stderr output
    # Get-AzureRmHDInsightJobOutput `
    #    -Clustername $clusterName `
    #    -JobId $job.JobId `
    #    -HttpCredential $creds `
    #    -DisplayOutputType StandardError
    Write-Progress -Activity $activity "Retrieving output..."
    Get-AzureRmHDInsightJobOutput `
        -Clustername $clusterName `
        -JobId $job.JobId `
        -HttpCredential $creds
}

function fix-lineending($original_file) {
    # Set $original_file to the python file path
    $text = [IO.File]::ReadAllText($original_file) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($original_file, $text)
}