$gitrepo="<replace-with-URL-of-your-own-GitHub-repo>"
$gittoken="<replace-with-a-GitHub-access-token>"
$webappname="mywebapp$(Get-Random)"
$location="West Europe"

# Create a resource group.
New-AzureRmResourceGroup -Name myResourceGroup -Location $location

# Create an App Service plan in Free tier.
New-AzureRmAppServicePlan -Name $webappname -Location $location `
-ResourceGroupName myResourceGroup -Tier Free

# Create a web app.
New-AzureRmWebApp -Name $webappname -Location $location -AppServicePlan $webappname `
-ResourceGroupName myResourceGroup

# SET GitHub
$PropertiesObject = @{
	token = $gittoken;
}
Set-AzureRmResource -PropertyObject $PropertiesObject `
-ResourceId /providers/Microsoft.Web/sourcecontrols/GitHub -ApiVersion 2015-08-01 -Force

# Configure GitHub deployment from your GitHub repo and deploy once.
$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
}
Set-AzureRmResource -PropertyObject $PropertiesObject -ResourceGroupName myResourceGroup `
-ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webappname/web `
-ApiVersion 2015-08-01 -Force

