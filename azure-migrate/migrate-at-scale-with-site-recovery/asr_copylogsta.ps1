Function Copy-AsrLogSta{
param(
    [String]$OutputFilePath,
    [String]$LogFileName
)

  $ResourceGroupName = "rg-migrate-lab"
  $StorageAccountName = "stmigrate187654"
  $ContainerName = "log-azure-migrate"

  Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName |
  Get-AzStorageContainer -Name $ContainerName |
  Set-AzStorageBlobContent -File $OutputFilePath -Blob $LogFileName
}