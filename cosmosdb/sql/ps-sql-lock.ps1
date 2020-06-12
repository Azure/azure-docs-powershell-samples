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
$collectionName = "myContainer"
# *****
$apiVersion = "2020-04-01" # Cosmos DB RP API version
$lockLevel = "CanNotDelete" # CanNotDelete or ReadOnly

$resourceTypeAccount = "Microsoft.DocumentDB/databaseAccounts"
$resourceTypeDatabase = "$resourceTypeAccount/sqlDatabases"
$resourceTypeCollection = "$resourceTypeDatabase/containers"

$resourceNameDatabase = "$accountName/$databaseName"
$lockNameDatabase = "$accountName-$databaseName-Lock"

$resourceNameCollection = "$accountName/$databaseName/$collectionName"
$lockNameCollection = "$accountName-$databaseName-$collectionName-Lock"
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

Write-Host "Create a $lockLevel lock on resource $resourceNameCollection"
New-AzResourceLock `
	-ApiVersion $apiVersion `
	-ResourceGroupName $resourceGroupName `
	-ResourceType $resourceTypeCollection `
	-ResourceName $resourceNameCollection `
	-LockName $lockNameCollection `
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

Write-Host "Delete lock on resource $resourceNameCollection"
Remove-AzResourceLock `
	-ApiVersion $apiVersion `
	-ResourceGroupName $resourceGroupName `
	-ResourceType $resourceTypeCollection `
	-ResourceName $resourceNameCollection `
	-LockName $lockNameCollection `
	-Force

Write-Host "List all locks on Cosmos DB account $accountName to confirm lock removal"
Get-AzResourceLock `
	-ApiVersion $apiVersion `
	-ResourceGroupName $resourceGroupName `
	-ResourceType $resourceTypeAccount `
	-ResourceName $accountName
