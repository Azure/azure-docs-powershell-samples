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

# Create an Azure Storage linked service in the data factory

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

## IMPORTANT: stores the JSON definition in a file that will be used by the New-AzureRMDataFactoryV2LinkedService command. 
$storageLinkedServiceDefinition | Out-File c:\StorageLinkedService.json

## Creates a linked service in the data factory
New-AzureRmDataFactoryV2LinkedService -DataFactory $df -Name "AzureStorageLinkedService" -File c:\StorageLinkedService.json

# Create an Azure Blob dataset in the data factory

## JSON definition of the dataset
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

## IMPORTANT: stores the JSON definition in a file that will be used by the New-AzureRmDataFactoryV2Dataset command. 
$datasetDefiniton | Out-File c:\BlobDataset.json

## Creates a dataset in the data factory
New-AzureRmDataFactoryV2Dataset -DataFactory $df -Name "BlobDataset" -File "c:\BlobDataset.json"

# Create a pipeline in the data factory

## JSON definition of the pipeline
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

## IMPORTANT: stores the JSON definition in a file that will be used by the New-AzureRmDataFactoryV2Pipeline command. 
$pipelineDefinition | Out-File c:\CopyPipeline.json

## Creates a pipeline in the data factory
New-AzureRmDataFactoryV2Pipeline -DataFactory $df -Name "CopyPipeline" -File "c:\CopyPipeline.json"

# Creates pipeline parameters for a run in the JSON format.
$pipelineParameters = @"
{
    "inputPath": "$sourceBlobPath",
    "outputPath": "$sinkBlobPath"
}
"@

## IMPORTANT: stores the JSON definition in a file that will be used by the New-AzureRmDataFactoryV2PipelineRun command. 
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

