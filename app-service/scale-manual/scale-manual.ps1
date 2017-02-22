
# Generates a Random Value
$Random=(New-Guid).ToString().Substring(0,8)

# Variables
$ResourceGroupName="myResourceGroup$random"
$AppName="AppServiceManualScale$random"
$Location="WestUS"

# Create a Resource Group
New-AzureRMResourceGroup -Name $ResourceGroupName -Location $Location

# Create an App Service Plan
New-AzureRMAppservicePlan -Name AppServiceManualScalePlan -ResourceGroupName $ResourceGroupName -Location $Location -Tier Basic

# Create a Web App in the App Service Plan
New-AzureRMWebApp -Name $AppName -ResourceGroupName $ResourceGroup -Location $Location -AppServicePlan AppServiceManualScalePlan

# Scale Web App to 2 Workers
Set-AzureRMAppServicePlan -NumberofWorkers 2 -Name AppServiceManualScalePlan -ResourceGroupName $ResourceGroupName