
# Generates a Random Value
$Random=(New-Guid).ToString().Substring(0,8)

# Variables
$ResourceGroupName="myResourceGroup$Random"
$AppName="AppServiceMonitor$Random"
$Location="WestUS"

# Create a Resource Group
New-AzResourceGroup -Name $ResourceGroupName -Location $Location

# Create an App Service Plan
New-AzAppservicePlan -Name AppServiceMonitorPlan -ResourceGroupName $ResourceGroupName -Location $Location -Tier Basic

# Create a Web App in the App Service Plan
New-AzWebApp -Name $AppName -ResourceGroupName $ResourceGroupName -Location $Location -AppServicePlan AppServiceMonitorPlan

# Enable Logs
Set-AzWebApp -RequestTracingEnabled $True -HttpLoggingEnabled $True -DetailedErrorLoggingEnabled $True -ResourceGroupName $ResourceGroupName -Name $AppName

# Make a Request
Invoke-WebRequest -Method "Get" -Uri https://$AppName.azurewebsites.net/404 -ErrorAction SilentlyContinue

# Download the Web App Logs
#Get-AzWebAppMetrics -ResourceGroupName $ResourceGroupName -Name $AppName -Metrics
