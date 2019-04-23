function Start-PigJob {
    # Script should stop on failures
    $ErrorActionPreference = "Stop"
    
    # Login to your Azure subscription
    $context = Get-AzContext
    if ($context -eq $null) 
    {
        Connect-AzAccount
    }
    $context

    # Get cluster info
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    $creds=Get-Credential -Message "Enter the login for the cluster"

    #Store the Pig Latin into $QueryString
    $QueryString =  "LOGS = LOAD '/example/data/sample.log';" +
    "LEVELS = foreach LOGS generate REGEX_EXTRACT(`$0, '(TRACE|DEBUG|INFO|WARN|ERROR|FATAL)', 1)  as LOGLEVEL;" +
    "FILTEREDLEVELS = FILTER LEVELS by LOGLEVEL is not null;" +
    "GROUPEDLEVELS = GROUP FILTEREDLEVELS by LOGLEVEL;" +
    "FREQUENCIES = foreach GROUPEDLEVELS generate group as LOGLEVEL, COUNT(FILTEREDLEVELS.LOGLEVEL) as COUNT;" +
    "RESULT = order FREQUENCIES by COUNT desc;" +
    "DUMP RESULT;"


    #Create a new HDInsight Pig Job definition
    $pigJobDefinition = New-AzHDInsightPigJobDefinition `
        -Query $QueryString `
        -Arguments "-w"

    # Start the Pig job on the HDInsight cluster
    Write-Host "Start the Pig job ..." -ForegroundColor Green
    $pigJob = Start-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobDefinition $pigJobDefinition `
        -HttpCredential $creds

    # Wait for the Pig job to complete
    Write-Host "Wait for the Pig job to complete ..." -ForegroundColor Green
    Wait-AzHDInsightJob `
        -ClusterName $clusterName `
        -JobId $pigJob.JobId `
        -HttpCredential $creds

    # Display the output of the Pig job.
    Write-Host "Display the standard output ..." -ForegroundColor Green
    Get-AzHDInsightJobOutput `
        -ClusterName $clusterName `
        -JobId $pigJob.JobId `
        -HttpCredential $creds
}