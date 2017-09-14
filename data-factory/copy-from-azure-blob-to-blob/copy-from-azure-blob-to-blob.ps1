# Set variables with your own values
$resourceGroupName = "<Name of the resource group>"
$dataFactoryName = "<Name of the data factory. Must be globally unique>"
$dataFactoryRegion = "East US" # Currently, you can create data factories only in East US region. Data stores and computes used by a data factory can be in other regions. 
$storageAccountName = "<Name of your Azure Storage account>"
$storageAccountKey = "<Key for your Azure Storage account>"
$sourceBlobPath = "<blob container>/<input folder>"
$sinkBlobPath = "<bloblcontainer>/<output folder>"

# Create a resource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $dataFactoryRegion

# Create a data factory
$df = Set-AzureRmDataFactoryV2 -ResourceGroupName $resourceGroupName -Location $dataFactoryRegion -Name $dataFactoryName -LoggingStorageAccountName $storageAccountName  -LoggingStorageAccountKey $storageAccountKey

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

## IMPORTANT: stores the JSON definition in a file that will be used by the Set-AzureRmDataFactoryV2LinkedService command. 
$storageLinkedServiceDefinition | Out-File c:\StorageLinkedService.json

## Creates a linked service in the data factory
Set-AzureRmDataFactoryV2LinkedService -DataFactory $df -Name "AzureStorageLinkedService" -File c:\StorageLinkedService.json

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

## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzureRmDataFactoryV2Dataset command. 
$datasetDefiniton | Out-File c:\BlobDataset.json

## Create a dataset in the data factory
Set-AzureRmDataFactoryV2Dataset -DataFactory $df -Name "BlobDataset" -File "c:\BlobDataset.json"

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

## IMPORTANT: store the JSON definition in a file that will be used by the Set-AzureRmDataFactoryV2Pipeline command. 
$pipelineDefinition | Out-File c:\CopyPipeline.json

## Create a pipeline in the data factory
Set-AzureRmDataFactoryV2Pipeline -DataFactory $df -Name "CopyPipeline" -File "c:\CopyPipeline.json"

# Create a pipeline run 

## JSON definition for pipeline parameters
$pipelineParameters = @"
{
    "inputPath": "$sourceBlobPath",
    "outputPath": "$sinkBlobPath"
}
"@

## IMPORTANT: store the JSON definition in a file that will be used by the Invoke-AzureRmDataFactoryV2PipelineRun command. 
$pipelineParameters | Out-File c:\PipelineParameters.json

# Create a pipeline run by using parameters
$runId = Invoke-AzureRmDataFactoryV2PipelineRun -DataFactory $df -PipelineName "CopyPipeline" -ParameterFile c:\PipelineParameters.json

# Check the pipeline run status until it finishes the copy operation
while ($True) {
    $result = Get-AzureRmDataFactoryV2ActivityRun -DataFactory $df -PipelineRunId $runId -PipelineName 'Adfv2QuickStartPipeline' -RunStartedAfter (Get-Date).AddMinutes(-30) -RunStartedBefore (Get-Date).AddMinutes(30)

    if (($result | Where-Object { $_.Status -eq "InProgress" } | Measure-Object).count -ne 0) {
        Write-Host "Pipeline run status: In Progress" -foregroundcolor "Yellow"
        Start-Sleep -Seconds 30
    }
    else {
        Write-Host "Pipeline 'Adfv2QuickStartPipeline' run finished. Result:" -foregroundcolor "Yellow"
        $result
        break
    }
}

# Get the activity run details 
$result = Get-AzureRmDataFactoryV2ActivityRun -DataFactory $df `
    $result = Get-AzureRmDataFactoryV2ActivityRun -DataFactory $df `
        -PipelineName "Adfv2QuickStartPipeline" `
        -PipelineRunId $runId `
        -RunStartedAfter (Get-Date).AddMinutes(-10) `
        -RunStartedBefore (Get-Date).AddMinutes(10) `
        -ErrorAction Stop

    $result

    if ($result.Status -eq "Succeeded") {`
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

