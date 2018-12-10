# You must have the latest version of the Event Grid PowerShell module.
# To install:
# Install-Module -Name AzureRM.EventGrid -AllowPrerelease -Force -Repository PSGallery

# Provide an endpoint for handling the events. Must be formatted "https://your-endpoint-URL"
$myEndpoint = "<your-endpoint-URL>"

# Get the subscription ID
$subID = (Get-AzureRmSubscription -SubscriptionName "<subscription-name>").Id

# Subscribe to the Azure subscription. The command creates the subscription for the currently selected Azure subscription. 
New-AzureRmEventGridSubscription -ResourceId "/subscriptions/$subID" -Endpoint $myEndpoint -EventSubscriptionName demoSubscriptionToAzureSub
