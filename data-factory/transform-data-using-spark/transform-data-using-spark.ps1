powershell Set-ExecutionPolicy Unrestricted -Scope CurrentUser

# Set variables with your own values
$resourceGroupName = "<Azure resource group name>"
$dataFactoryName = "<Data factory name. Must be globally unique.>"
$dataFactoryRegion = "East US" 
$storageAccountName = "<Az.Storage account name> "
$storageAccountKey = "<Az.Storage account key>"
$subscriptionID = "<Azure subscription ID>"
$tenantID = "<tenant ID>"
$servicePrincipalID = "<Active directory service principal ID>"
$servicePrincipalKey = "<Active directory service principal key>"

$pipelineName = "SparkTransformPipeline"

# Create a resource group
New-AzResourceGroup -Name $resourceGroupName -Location $dataFactoryRegion

# Create a data factory
$df = Set-AzDataFactory -ResourceGroupName $resourceGroupName -Location $dataFactoryRegion -Name $dataFactoryName

# Create an Az.Storage linked service in the data factory

## JSON definition of the linked service. 
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

## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzDataFactoryLinkedService command. 
$storageLinkedServiceDefinition | Out-File c:\AzureStorageLinkedService.json

## Creates an Az.Storage linked service
Set-AzDataFactoryLinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name "AzureStorageLinkedService" -File c:\AzureStorageLinkedService.json

# Create on-demand Spark linked service in the data factory

## JSON definition of the linked service. 
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

## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzDataFactoryLinkedService command. 
$sparkLinkedServiceDefinition | Out-File c:\OnDemandSparkLinkedService.json

# Creates an on-demand Spark linked service
Set-AzDataFactoryLinkedService -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name "OnDemandSparkLinkedService" -File "C:\OnDemandSparkLinkedService.json"

# Create a pipeline in the data factory

## JSON definition of the pipeline
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

## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzDataFactoryPipeline command.
$pipelineDefinition | Out-File c:\SparkTransformPipeline.json

## Create a pipeline with Spark Activity in the data factory
Set-AzDataFactoryPipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -Name "SparkTransformPipeline" -File "c:\SparkTransformPipeline.json"

# Create a pipeline run 

## JSON definition for dummy pipeline parameters
$pipelineParameters = @"
{
    "dummy":  "b"
}
"@

## IMPORTANT: store the JSON definition in a file that will be used by the Invoke-AzDataFactoryPipeline command. 
$pipelineParameters | Out-File c:\PipelineParameters.json

# Create a pipeline run by using parameters
$runId = Invoke-AzDataFactoryPipeline -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -PipelineName $pipelineName -ParameterFile c:\PipelineParameters.json

# Check the pipeline run status until it finishes
Start-Sleep -Seconds 30
while ($True) {
    $result = Get-AzDataFactoryActivityRun -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName -PipelineRunId $runId -RunStartedAfter (Get-Date).AddMinutes(-30) -RunStartedBefore (Get-Date).AddMinutes(30)

    if (($result | Where-Object { $_.Status -eq "InProgress" } | Measure-Object).count -ne 0) {
        Write-Host "Pipeline run status: In Progress" -foregroundcolor "Yellow"
        Start-Sleep -Seconds 300
    }
    else {
        Write-Host "Pipeline $pipelineName run finished. Result:" -foregroundcolor "Yellow"
        $result
        break
    }
}

# Get the activity run details 
$result = Get-AzDataFactoryActivityRun -DataFactoryName $dataFactoryName -ResourceGroupName $resourceGroupName `
    -PipelineRunId $runId `
    -RunStartedAfter (Get-Date).AddMinutes(-30) `
    -RunStartedBefore (Get-Date).AddMinutes(30) `
    -ErrorAction Stop

$result

if ($result.Status -eq "Succeeded") {`
    $result.Output -join "`r`n"`
}`
else {`
    $result.Error -join "`r`n"`
}

# To remove the data factory from the resource gorup
# Remove-AzDataFactory -Name $dataFactoryName -ResourceGroupName $resourceGroupName
# 
# To remove the whole resource group
# Remove-AzResourceGroup  -Name $resourceGroupName
