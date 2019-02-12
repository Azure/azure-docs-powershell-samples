
# Generates a Random Value
$Random=(New-Guid).ToString().Substring(0,8)

# Variables
$ResourceGroupName="myResourceGroup$Random"
$App1Name="AppServiceTM1$Random"
$App2Name="AppServiceTM2$Random"
$Location1="WestUS"
$Location2="EastUS"

# Create a Resource Group
New-AzResourceGroup -Name $ResourceGroupName -Location $Location1

# Create Traffic Manager Profile
New-AzTrafficManagerProfile -Name "$ResourceGroupName-tmp" -ResourceGroupName $ResourceGroupName -TrafficRoutingMethod Performance -MonitorPath '/' -MonitorProtocol "HTTP" -RelativeDnsName $ResourceGroupName -Ttl 30 -MonitorPort 80

# Create an App Service Plan
New-AzAppservicePlan -Name "$App1Name-Plan" -ResourceGroupName $ResourceGroupName -Location $Location1 -Tier Standard
New-AzAppservicePlan -Name "$App2Name-Plan" -ResourceGroupName $ResourceGroupName -Location $Location2 -Tier Standard

# Create a Web App in the App Service Plan
$App1ResourceId=(New-AzWebApp -Name $App1Name -ResourceGroupName $ResourceGroupName -Location $Location1 -AppServicePlan "$App1Name-Plan").Id
$App2ResourceId=(New-AzWebApp -Name $App2Name -ResourceGroupName $ResourceGroupName -Location $Location2 -AppServicePlan "$App2Name-Plan").Id

# Create Traffic Manager Endpoints for Web Apps
New-AzTrafficManagerEndpoint -Name "$App1Name-$Location1" -ResourceGroupName $ResourceGroupName -ProfileName "$ResourceGroupName-tmp" -Type AzureEndpoints -TargetResourceId $App1ResourceId -EndpointStatus "Enabled"
New-AzTrafficManagerEndpoint -Name "$App2Name-$Location2" -ResourceGroupName $ResourceGroupName -ProfileName "$ResourceGroupName-tmp" -Type AzureEndpoints -TargetResourceId $App2ResourceId -EndpointStatus "Enabled"
