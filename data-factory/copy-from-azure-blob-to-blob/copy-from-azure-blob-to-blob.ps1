powershell Set-ExecutionPolicy Unrestricted -Scope CurrentUser

# Set variables with your own values
$resourceGroupName = "<Name of the resource group>"
$dataFactoryName = "<Name of the data factory. Must be globally unique>"
$dataFactoryRegion = "East US" # Currently, you can create data factories only in East US region. Data stores and computes used by a data factory can be in other regions. 
$storageAccountName = "<Name of your Azure Storage account>"
$storageAccountKey = "<Key for your Azure Storage account>"
$sourceBlobPath = "<blob container>/<input folder>"
$sinkBlobPath = "<bloblcontainer>/<output folder>"

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
$storageLinkedServiceDefinition | Out-File c:\StorageLinkedService.json
New-AzureRmDataFactoryV2LinkedService -DataFactory $df -Name "AzureStorageLinkedService" -File c:\StorageLinkedService.json

# Create a dataset in the data factory
$datasetDefiniton = @"
{
    "name": "BlobDataset",
    "properties": {
        "type": "AzureBlob",
        "typeProperties": {
            "folderPath": {
                "value": "@{dataset().path}",
                "type": "Expression"
            }
        },
        "linkedServiceName": {
            "referenceName": "AzureStorageLinkedService",
            "type": "LinkedServiceReference"
        },
        "parameters": {
            "path": {
                "type": "String"
            }
        }
    }
}
"@
$datasetDefiniton | Out-File c:\BlobDataset.json
New-AzureRmDataFactoryV2Dataset -DataFactory $df -Name "BlobDataset" -File "c:\BlobDataset.json"

# Create a pipeline in the data factory
$pipelineDefinition = @"
{
    "name": "Adfv2QuickStartPipeline",
    "properties": {
        "activities": [
            {
                "name": "CopyFromBlobToBlob",
                "type": "Copy",
                "inputs": [
                    {
                        "referenceName": "BlobDataset",
                        "parameters": {
                            "path": "@pipeline().parameters.inputPath"
                        },
                    "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "BlobDataset",
                        "parameters": {
                            "path": "@pipeline().parameters.outputPath"
                        },
                        "type": "DatasetReference"
                    }
                ],
                "typeProperties": {
                    "source": {
                        "type": "BlobSource"
                    },
                    "sink": {
                        "type": "BlobSink"
                    }
                }
            }
        ],
        "parameters": {
            "inputPath": {
                "type": "String"
            },
            "outputPath": {
                "type": "String"
            }
        }
    }
}
"@
$pipelineDefinition | Out-File c:\CopyPipeline.json
New-AzureRmDataFactoryV2Pipeline -DataFactory $df -Name "CopyPipeline" -File "c:\CopyPipeline.json"

# Create pipeline parameters for a run
$pipelineParameters = @"
{
    "inputPath": "$sourceBlobPath",
    "outputPath": "$sinkBlobPath"
}
"@
$pipelineParameters | Out-File c:\PipelineParameters.json

# Create a pipeline run by using parameters
$runId = New-AzureRmDataFactoryV2PipelineRun -DataFactory $df -PipelineName "CopyPipeline" -ParameterFile c:\PipelineParameters.json

# Check the pipeline run status until it finishes the copy operation
while ($True) {
    $run = Get-AzureRmDataFactoryV2PipelineRun -DataFactory $df -RunId $runId -ErrorAction Stop
    Write-Host  "Pipeline run status: " $run.Status -foregroundcolor "Yellow"

    if ($run.Status -eq "InProgress") {
        Start-Sleep -Seconds 15
    }
    else {
        $run
        break
    }
}

# Get the activity run details 
$result = Get-AzureRmDataFactoryV2ActivityRun -DataFactory $df `
    -PipelineName "Adfv2QuickStartPipeline" `
    -PipelineRunId $runId `
    -RunStartedAfter (Get-Date).AddMinutes(-10) `
    -RunStartedBefore (Get-Date).AddMinutes(10) `
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

