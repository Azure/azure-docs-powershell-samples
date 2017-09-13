Set-ExecutionPolicy Unrestricted -Scope CurrentUser

##### Azure-SSIS integration runtime (IR) specifications

# If your inputs contain PSH special characters, e.g. "$", please precede it with the escape character "`" like "`$". 

# Azure Data Factory information
$SubscriptionName = "<your azure subscription name>"
$ResourceGroupName = "<azure resource group name>"
$DataFactoryName = "<globablly unique name for your data factory>"
$DataFactoryLocation = "EastUS" # data factory v2 can be created only in east us region. 
$DataFactoryLoggingStorageAccountName = "<storage account name>"
$DataFactoryLoggingStorageAccountKey = "<storage account key>"

# Azure-SSIS IR information
$AzureSsisIRName = "<name of Azure-SSIS IR>"
$AzureSsisIRDescription = "This is my Azure-SSIS IR instance"
$AzureSsisIRLocation = "EastUS" # only East US|North Europe are supported
$AzureSsisIRNodeSize = "Standard_A4_v2" # currently, only Standard_A4_v2|Standard_A8_v2|Standard_D1_v2|Standard_D2_v2|Standard_D3_v2|Standard_D4_v2 are supported 
$AzureSsisIRNodeNumber = 2 # only 1-10 nodes are supported
$AzureSsisIRMaxParallelExecutionsPerNode = 2 # only 1-8 parallel executions per node are supported
$VnetId = "" # OPTIONAL: only classic VNet is supported
$SubnetName = "" # OPTIONAL: only classic VNet is supported

# SSISDB information
$SSISDBServerEndpoint = "<your azure sql server name>.database.windows.net"
$SSISDBServerAdminUserName = "<sql server admin user ID>"
$SSISDBServerAdminPassword = "<sql server admin password>"
$SSISDBPricingTier = "<your azure sql database pricing tier, e.g. S0, S3, or leave it empty for azure sql managed instance>" # Not applicable for Azure SQL MI

##### End of Azure-SSIS IR specifications ##### 

$SSISDBConnectionString = "Data Source=" + $SSISDBServerEndpoint + ";User ID="+ $SSISDBServerAdminUserName +";Password="+ $SSISDBServerAdminPassword

##### Validate Azure SQL DB/MI server ##### 

$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $SSISDBConnectionString;
Try
{
    $sqlConnection.Open();
}
Catch [System.Data.SqlClient.SqlException]
{
    Write-Warning "Cannot connect to your Azure SQL DB logical server/Azure SQL MI server, exception: $_"  ;
    Write-Warning "Please make sure the server you specified has already been created. Do you want to proceed? [Y/N]"
    $yn = Read-Host
    if(!($yn -ieq "Y"))
    {
        Return;
    } 
}


##### Automatically configure VNet permissions/settings for Azure-SSIS IR to join ##### 

# Register to Azure Batch resource provider
if(![string]::IsNullOrEmpty($VnetId) -and ![string]::IsNullOrEmpty($SubnetName))
{
    $BatchObjectId = (Get-AzureRmADServicePrincipal -ServicePrincipalName "MicrosoftAzureBatch").Id
    Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Batch
    while(!(Get-AzureRmResourceProvider -ProviderNamespace "Microsoft.Batch").RegistrationState.Contains("Registered"))
    {
	Start-Sleep -s 10
    }
    # Assign VM contributor role to Microsoft.Batch
    New-AzureRmRoleAssignment -ObjectId $BatchObjectId -RoleDefinitionName "Classic Virtual Machine Contributor" -Scope $VnetId
}

##### Provision data factory + Azure-SSIS IR ##### 

# Create an Azure resource gorup. 
New-AzureRmResourceGroup -Location $DataFactoryLocation -Name $ResourceGroupName

# Create data factory
New-AzureRmDataFactoryV2 -Location $DataFactoryLocation -LoggingStorageAccountName $DataFactoryLoggingStorageAccountName -LoggingStorageAccountKey $DataFactoryLoggingStorageAccountKey -Name $DataFactoryName -ResourceGroupName $ResourceGroupName 

# Create Azure-SSIS IR
New-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -Name $AzureSsisIRName -ResourceGroupName $ResourceGroupName -Type Managed -CatalogServerEndpoint $SSISDBServerEndpoint -CatalogAdminUserName $SSISDBServerAdminUserName -CatalogAdminPassword $SSISDBServerAdminPassword -CatalogPricingTier $SSISDBPricingTier -Description $AzureSsisIRDescription -Location $AzureSsisIRLocation -NodeSize $AzureSsisIRNodeSize -NumberOfNodes $AzureSsisIRNodeNumber -MaxParallelExecutionsPerNode $AzureSsisIRMaxParallelExecutionsPerNode -VnetId $VnetId -Subnet $SubnetName

# Starting Azure-SSIS IR that can run SSIS packages in the cloud
write-host("##### Starting #####")
Start-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -Name $AzureSsisIRName -ResourceGroupName $ResourceGroupName -Sync -Force
write-host("##### Completed #####")
write-host("If any cmdlet is unsuccessful, please consider using -Debug option for diagnostics.")

##### Get Azure-SSIS IR status #####

Get-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -Name $AzureSsisIRName -ResourceGroupName $ResourceGroupName
Get-AzureRmDataFactoryV2IntegrationRuntimeStatus -DataFactoryName $DataFactoryName -Name $AzureSsisIRName -ResourceGroupName $ResourceGroupName

##### Reconfigure Azure-SSIS IR, e.g. scale out from 2 to 5 nodes #####

#Stop-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -Name $AzureSsisIRName -ResourceGroupName $ResourceGroupName 
#Set-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -Name $AzureSsisIRName -ResourceGroupName $ResourceGroupName -NumberOfNodes 5
#Start-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -Name $AzureSsisIRName -ResourceGroupName $ResourceGroupName -Sync

##### Clean up ######

#Stop-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -Name $AzureSsisIRName -ResourceGroupName $ResourceGroupName -Force
#Remove-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -Name $AzureSsisIRName -ResourceGroupName $ResourceGroupName -Force
#Remove-AzureRmDataFactoryV2 -Name $DataFactoryName -ResourceGroupName $ResourceGroupName -Force
#Remove-AzureRmResourceGroup -Name $ResourceGroupName -Force