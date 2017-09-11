powershell Set-ExecutionPolicy Unrestricted -Scope CurrentUser

# Set variables with your own values
$resourceGroupName = "<Azure resource group name>"
$dataFactoryName = "<Data factory name. Must be globally unique."
$dataFactoryRegion = "East US" # Data factory can only be created in East US. Data stores and compute services can be in other regions. 
$storageAccountName = "<Azure Storage account name> "
$storageAccountKey = "Azure Storage account key"
$subscriptionID = "<Azure subscription ID>"
$tenantID = "<tenant ID>"
$servicePrincipalID = "<Active directory service principal ID>"
$servicePrincipalKey = "<Active directory service principal key>"


# Login to your Azure account
Login-AzureRmAccount

# Create a resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $dataFactoryRegion

# Create a data factory
$df = New-AzureRmDataFactoryV2 -ResourceGroupName $resourceGroupName -Location $dataFactoryRegion -Name $dataFactoryName -LoggingStorageAccountName $storageAccountName  -LoggingStorageAccountKey $storageAccountKey

# Create a storage linked service in the data factory
$storageLinkedServiceDefinition = @"
{
    "name": "AzureStorageLinkedService",
    "properties": {
        "type": "AzureStorage",
        "typeProperties": {
            "connectionString": {
                "value": "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageAccountKey",
                "type": "SecureString"
            }
        }
    }
}
"@
$storageLinkedServiceDefinition | Out-File c:\AzureStorageLinkedService.json
New-AzureRmDataFactoryV2LinkedService -DataFactory $df -Name "AzureStorageLinkedService" -File c:\AzureStorageLinkedService.json

# Create on-demand Spark linked service
$sparkLinkedServiceDefinition = @"
{
    "name": "OnDemandSparkLinkedService",
    "properties": {
      "type": "HDInsightOnDemand",
      "typeProperties": {
        "clusterSize": 2,
        "clusterType": "spark",
        "timeToLive": "00:15:00",
        "hostSubscriptionId": "$subscriptionID",
        "servicePrincipalId": "$servicePrincipalID",
        "servicePrincipalKey": {
          "value": "$servicePrincipalKey",
          "type": "SecureString"
        },
        "tenant": "$tenantID",
        "clusterResourceGroup": "$resourceGroupName",
        "version": "3.6",
        "osType": "Linux",
        "clusterNamePrefix":"ADFSparkSample",
        "linkedServiceName": {
          "referenceName": "AzureStorageLinkedService",
          "type": "LinkedServiceReference"
        }
      }
    }
}
"@
$sparkLinkedServiceDefinition | Out-File c:\OnDemandSparkLinkedService.json
New-AzureRmDataFactoryV2LinkedService -DataFactory $df -Name "OnDemandSparkLinkedService" -File "C:\OnDemandSparkLinkedService.json"

# Create a pipeline in the data factory
$pipelineDefinition = @"
{
  "name": "SparkTransformPipeline",
  "properties": {
    "activities": [
      {
        "name": "MySparkActivity",
        "type": "HDInsightSpark",
        "linkedServiceName": {
            "referenceName": "OnDemandSparkLinkedService",
            "type": "LinkedServiceReference"
        },
        "typeProperties": {
          "rootPath": "adftutorial/spark",
          "entryFilePath": "script/WordCount_Spark.py",
          "getDebugInfo": "Failure",
          "sparkJobLinkedService": {
            "referenceName": "AzureStorageLinkedService",
            "type": "LinkedServiceReference"
          }
        }
      }
    ]
  }
}
"@
$pipelineDefinition | Out-File c:\SparkTransformPipeline.json
New-AzureRmDataFactoryV2Pipeline -DataFactory $df -Name "SparkTransformPipeline" -File "c:\SparkTransformPipeline.json"

# Create dummy pipeline parameter for a run
$pipelineParameters = @"
{
    "dummy":  "b"
}
"@
$pipelineParameters | Out-File c:\PipelineParameters.json

# Create a pipeline run by using parameters
$runId = New-AzureRmDataFactoryV2PipelineRun -DataFactory $df -PipelineName "SparkTransformPipeline" -ParameterFile c:\PipelineParameters.json

# Check the pipeline run status until it finishes the copy operation
while ($True) {
    $run = Get-AzureRmDataFactoryV2PipelineRun -DataFactory $df -RunId $runId -ErrorAction Stop
    Write-Host  "Pipeline run status: " $run.Status -foregroundcolor "Yellow"

    if ($run.Status -eq "InProgress") {
        Start-Sleep -Seconds 300
    }
    else {
        $run
        break
    }
}

# Get the activity run details 
$result = Get-AzureRmDataFactoryV2ActivityRun -DataFactory $df `
    -PipelineName "SparkTransformPipeline" `
    -PipelineRunId $runId `
    -RunStartedAfter (Get-Date).AddMinutes(-30) `
    -RunStartedBefore (Get-Date).AddMinutes(30) `
    -ErrorAction Stop

$result

if ($run.Status -eq "Succeeded") {`
    $result.Output -join "`r`n"`
}`
else {`
    $result.Error -join "`r`n"`
}

# To remove the data factory from the resource gorup
# Remove-AzureRmDataFactoryV2 -Name $dataFactoryName -ResourceGroupName $resourceGroupName
# 
# To remove the whole resource group
# Remove-AzureRmResourceGroup  -Name $resourceGroupName
