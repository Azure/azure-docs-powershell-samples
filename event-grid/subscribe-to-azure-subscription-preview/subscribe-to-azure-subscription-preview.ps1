# You must have the latest version of the Event Grid PowerShell module.
# To install:
# Install-Module -Name AzureRM.EventGrid -AllowPrerelease -Force -Repository PSGallery

# Provide an endpoint for handling the events.
$myEndpoint = "<endpoint URL>"

# Select the Azure subscription you want to subscribe to.
Set-AzureRmContext -Subscription "Contoso Subscription"

# Get the subscription ID
$subID = (Get-AzureRmSubscription -SubscriptionName "Contoso Subscription").Id

# Subscribe to the Azure subscription. The command creates the subscription for the currently selected Azure subscription. 
New-AzureRmEventGridSubscription -ResourceId "/subscriptions/$subID" -Endpoint $myEndpoint -EventSubscriptionName demoSubscriptionToAzureSub