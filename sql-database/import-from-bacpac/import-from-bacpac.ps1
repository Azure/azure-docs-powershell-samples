# Set an admin login and password for your database
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# The logical server name has to be unique in the system
$servername = "server-$(Get-Random)"
# The storage account name has to be unique in the system
$storageaccountname = "sqlimport$(Get-Random)"
# The ip address range that you want to allow to access your DB
$startip = "0.0.0.0"
$endip = "255.255.255.255"

# Create a resource group
New-AzureRmResourceGroup -Name "myResourceGroup" -Location "westeurope"

# Create a storage account 
New-AzureRmStorageAccount -ResourceGroupName "myResourceGroup" `
    -AccountName $storageaccountname `
    -Location "westeurope" `
    -Type "Standard_LRS"

# Create a storage container 
New-AzureStorageContainer -Name "importsample" `
    -Context $(New-AzureStorageContext -StorageAccountName $storageaccountname `
        -StorageAccountKey $(Get-AzureRmStorageAccountKey -ResourceGroupName "myResourceGroup" -StorageAccountName $storageaccountname).Value[0])

# Download sample database from Github
Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac" -OutFile "sample.bacpac"

# Upload sample database into storage container
Set-AzureStorageBlobContent -Container "importsample" `
    -File "sample.bacpac" `
    -Context $(New-AzureStorageContext -StorageAccountName $storageaccountname `
        -StorageAccountKey $(Get-AzureRmStorageAccountKey -ResourceGroupName "myResourceGroup" -StorageAccountName $storageaccountname).Value[0])

# Create a new server with a system wide unique server name
New-AzureRmSqlServer -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -Location "westeurope" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "ServerAdmin", $(ConvertTo-SecureString -String "ASecureP@assw0rd" -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
New-AzureRmSqlServerFirewallRule -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startip -EndIpAddress $endip

# Import bacpac to database with an S3 performance level
$importRequest = New-AzureRmSqlDatabaseImport -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "myImportSample" `
    -DatabaseMaxSizeBytes "262144000" `
    -StorageKeyType "StorageAccessKey" `
    -StorageKey $(Get-AzureRmStorageAccountKey -ResourceGroupName "myResourceGroup" -StorageAccountName $storageaccountname).Value[0] `
    -StorageUri "http://$storageaccountname.blob.core.windows.net/importsample/sample.bacpac" `
    -Edition "Standard" `
    -ServiceObjectiveName "S3" `
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

# Scale down to S0 after import is complete
Set-AzureRmSqlDatabase -ResourceGroupName "myResourceGroup" `
    -ServerName $servername `
    -DatabaseName "myImportSample" `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S0"
