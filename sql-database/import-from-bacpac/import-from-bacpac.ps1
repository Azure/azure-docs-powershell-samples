# Sign in
# Login-AzureRmAccount


# Creat a new resource group
New-AzureRmResourceGroup -Name "ImportSampleResourceGroup" -Location "northcentralus"


# Create a new Storage Account 
New-AzureRmStorageAccount -ResourceGroupName "ImportSampleResourceGroup" `
    -AccountName $("sql$($(Get-AzureRMContext).Subscription.SubscriptionId)").substring(0,23).replace("-", "") `
    -Location "northcentralus" `
    -Type "Standard_LRS"


# Create a new storage container 
New-AzureStorageContainer -Name "importsample" `
    -Context $(New-AzureStorageContext -StorageAccountName $("sql$($(Get-AzureRMContext).Subscription.SubscriptionId)").substring(0,23).replace("-", "") `
        -StorageAccountKey $(Get-AzureRmStorageAccountKey -ResourceGroupName "ImportSampleResourceGroup" -StorageAccountName $("sql$($(Get-AzureRMContext).Subscription.SubscriptionId)").substring(0,23).replace("-", "")).Value[0])

  
# Download sample database from Github
Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac" -OutFile "sample.bacpac"


# Upload sample database into storage container
Set-AzureStorageBlobContent -Container "importsample" `
    -File "sample.bacpac" `
    -Context $(New-AzureStorageContext -StorageAccountName $("sql$($(Get-AzureRMContext).Subscription.SubscriptionId)").substring(0,23).replace("-", "") `
        -StorageAccountKey $(Get-AzureRmStorageAccountKey -ResourceGroupName "ImportSampleResourceGroup" -StorageAccountName $("sql$($(Get-AzureRMContext).Subscription.SubscriptionId)").substring(0,23).replace("-", "")).Value[0])


# Create a new server with a system wide unique server-name
New-AzureRmSqlServer -ResourceGroupName "ImportSampleResourceGroup" `
    -ServerName "import-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -Location "northcentralus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ServerAdmin", $(ConvertTo-SecureString -String "ASecureP@assw0rd" -AsPlainText -Force))


# Open up the server firewall so we can connect
New-AzureRmSqlServerFirewallRule -ResourceGroupName "ImportSampleResourceGroup" `
    -ServerName "import-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -FirewallRuleName "AllowAll" -StartIpAddress "0.0.0.0" -EndIpAddress "255.255.255.255"


# Import bacpac
$importRequest = New-AzureRmSqlDatabaseImport -ResourceGroupName "ImportSampleResourceGroup" `
    -ServerName "import-server-$($(Get-AzureRMContext).Subscription.SubscriptionId)" `
    -DatabaseName "MyImportSample" `
    -DatabaseMaxSizeBytes "262144000" `
    -StorageKeyType "StorageAccessKey" `
    -StorageKey $(Get-AzureRmStorageAccountKey -ResourceGroupName "ImportSampleResourceGroup" -StorageAccountName $("sql$($(Get-AzureRMContext).Subscription.SubscriptionId)").substring(0,23).replace("-", "")).Value[0] `
    -StorageUri "http://$($("sql$($(Get-AzureRMContext).Subscription.SubscriptionId)").substring(0,23).replace("-", """)).blob.core.windows.net/importsample/sample.bacpac" `
    -Edition "Standard" `
    -ServiceObjectiveName "S0" `
    -AdministratorLogin "ServerAdmin" `
    -AdministratorLoginPassword $(ConvertTo-SecureString -String "ASecureP@assw0rd" -AsPlainText -Force)


# Check import status and wait for the import to complete
$importStatus = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
[Console]::Write("Importing")
while ($importStatus.Status -eq "InProgress")
{
    $importStatus = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    [Console]::Write(".")
    Start-Sleep -s 10
}
[Console]::WriteLine("")
$importStatus


# Clean up: Delete the resources group and ALL resources in the resource group
# Remove-AzureRmResourceGroup -ResourceGroupName "ImportSampleResourceGroup"
# Remove-Item sample.bacpac