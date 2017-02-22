
# Generates a Random Value
$Random=(New-Guid).ToString().Substring(0,8)

# Variables
$ResourceGroup="MyResourceGroup$Random"
$AppName="webappwithStorage$Random"
$StorageName="webappstorage$Random"
$Location="West US"

# Create a Resource Group
New-AzureRMResourceGroup -Name $ResourceGroup -Location $Location

# Create an App Service Plan
New-AzureRMAppservicePlan -Name WebAppwithStoragePlan -ResourceGroupName $ResourceGroup -Location $Location -Tier Basic

# Create a Web App in the App Service Plan
New-AzureRMWebApp -Name $AppName -ResourceGroupName $ResourceGroup -Location $Location -AppServicePlan WebAppwithStoragePlan

# Create Storage Account
New-AzureRMStorageAccount -Name $StorageName -ResourceGroupName $ResourceGroup -Location $Location -SkuName Standard_LRS

# Get Connection String for Storage Account
$StorageKey=(Get-AzureRMStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageName).Value[0]

# Assign Connection String to App Setting 
Set-AzureRMWebApp -ConnectionStrings @{ MyStorageConnStr = @{ Type="Custom"; Value="DefaultEndpointsProtocol=https;AccountName=$StorageName;AccountKey=$StorageKey;" } } -Name $AppName -ResourceGroupName $ResourceGroup