# References:
# Az.CosmosDB | https://docs.microsoft.com/powershell/module/az.cosmosdb
# Az.Resources | https://docs.microsoft.com/powershell/module/az.resources
# --------------------------------------------------
# Purpose
# 
# --------------------------------------------------
# Variables
# ***** SUBSTITUTE YOUR VALUES *****
$resourceGroupName = "myResourceGroup"
$accountName = "myaccount"
$databaseName = "myDatabase"
# *****
$apiVersion = "2020-04-01" # Cosmos DB RP API version
$lockLevel = "CanNotDelete" # CanNotDelete or ReadOnly

$resourceTypeAccount = "Microsoft.DocumentDB/databaseAccounts"
$resourceTypeDatabase = "$resourceTypeAccount/tables"

$resourceNameDatabase = "$accountName/$databaseName"
$lockNameDatabase = "$accountName-$databaseName-Lock"
# --------------------------------------------------

Write-Host "Create a $lockLevel lock on resource $resourceNameDatabase"
New-AzResourceLock `
	-ApiVersion $apiVersion `
	-ResourceGroupName $resourceGroupName `
	-ResourceType $resourceTypeDatabase `
	-ResourceName $resourceNameDatabase `
	-LockName $lockNameDatabase `
	-LockLevel $lockLevel `
	-Force

Write-Host "List all locks on  Cosmos DB account $accountName to confirm lock creation"
Get-AzResourceLock `
	-ApiVersion $apiVersion `
	-ResourceGroupName $resourceGroupName `
	-ResourceType $resourceTypeAccount `
	-ResourceName $accountName

Write-Host "Delete lock on resource $resourceNameDatabase"
Remove-AzResourceLock `
	-ApiVersion $apiVersion `
	-ResourceGroupName $resourceGroupName `
	-ResourceType $resourceTypeDatabase `
	-ResourceName $resourceNameDatabase `
	-LockName $lockNameDatabase `
	-Force

Write-Host "List all locks on Cosmos DB account $accountName to confirm lock removal"
Get-AzResourceLock `
	-ApiVersion $apiVersion `
	-ResourceGroupName $resourceGroupName `
	-ResourceType $resourceTypeAccount `
	-ResourceName $accountName
