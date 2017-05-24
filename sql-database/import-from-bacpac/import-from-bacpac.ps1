# Login-AzureRmAccount
# Set the resource group name and location for your server
$resourcegroupname = "myResourceGroup-$(Get-Random)"
$location = "westeurope"
# Set an admin login and password for your server
$adminlogin = "ServerAdmin"
$password = "ChangeYourAdminPassword1"
# Set server name - the logical server name has to be unique in the system
$servername = "server-$(Get-Random)"
# The sample database name
$databasename = "myImportedDatabase"
# The storage account name and storage container name
$storageaccountname = "sqlimport$(Get-Random)"
$storagecontainername = "importcontainer$(Get-Random)"
# BACPAC file name
$bacpacfilename = "sample.bacpac"
# The ip address range that you want to allow to access your server
$startip = "0.0.0.0"
$endip = "0.0.0.0"

# Create a resource group
$resourcegroup = New-AzureRmResourceGroup -Name $resourcegroupname -Location $location

# Create a storage account 
$storageaccount = New-AzureRmStorageAccount -ResourceGroupName $resourcegroupname `
    -AccountName $storageaccountname `
    -Location $location `
    -Type "Standard_LRS"

# Create a storage container 
$storagecontainer = New-AzureStorageContainer -Name $storagecontainername `
    -Context $(New-AzureStorageContext -StorageAccountName $storageaccountname `
        -StorageAccountKey $(Get-AzureRmStorageAccountKey -ResourceGroupName $resourcegroupname -StorageAccountName $storageaccountname).Value[0])

# Download sample database from Github
Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac" -OutFile $bacpacfilename

# Upload sample database into storage container
Set-AzureStorageBlobContent -Container $storagecontainername `
    -File $bacpacfilename `
    -Context $(New-AzureStorageContext -StorageAccountName $storageaccountname `
        -StorageAccountKey $(Get-AzureRmStorageAccountKey -ResourceGroupName $resourcegroupname -StorageAccountName $storageaccountname).Value[0])

# Create a new server with a system wide unique server name
$server = New-AzureRmSqlServer -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
$serverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startip -EndIpAddress $endip

# Import bacpac to database with an S3 performance level
$importRequest = New-AzureRmSqlDatabaseImport -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -DatabaseName $databasename `
    -DatabaseMaxSizeBytes "262144000" `
    -StorageKeyType "StorageAccessKey" `
    -StorageKey $(Get-AzureRmStorageAccountKey -ResourceGroupName $resourcegroupname -StorageAccountName $storageaccountname).Value[0] `
    -StorageUri "http://$storageaccountname.blob.core.windows.net/$storagecontainername/$bacpacfilename" `
    -Edition "Standard" `
    -ServiceObjectiveName "S3" `
    -AdministratorLogin "$adminlogin" `
    -AdministratorLoginPassword $(ConvertTo-SecureString -String $password -AsPlainText -Force)

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
Set-AzureRmSqlDatabase -ResourceGroupName $resourcegroupname `
    -ServerName $servername `
    -DatabaseName $databasename  `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S0"

# Clean up deployment 
# Remove-AzureRmResourceGroup -ResourceGroupName $resourcegroupname