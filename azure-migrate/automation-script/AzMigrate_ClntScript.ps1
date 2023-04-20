
Import-Module az
Connect-AzAccount

$ErrorActionPreference = "Stop"

$scriptsPath = $PSScriptRoot
if ($PSScriptRoot -eq "") {
    $scriptsPath = "."
}

#Initiate replication
#. "$scriptsPath\AzMigrate_StartReplication.ps1" .\Input.csv
# Get Updated replication Status
. "$scriptsPath\AzMigrate_UpdateReplicationStatus.ps1" .\Input.csv

# #Start TestMigration
#. "$scriptsPath\AzMigrate_StartTestMigration.ps1" .\Input.csv
# Get Updated replication Status
#. "$scriptsPath\AzMigrate_UpdateReplicationStatus.ps1" .\Input.csv

# #Cleanup TestMigration
# . "$scriptsPath\AzMigrate_CleanupTestMigration.ps1" .\Input.csv
# Get Updated replication Status
# . "$scriptsPath\AzMigrate_UpdateReplicationStatus.ps1" .\Input.csv

# #UpdateMachineProperties
#. "$scriptsPath\AzMigrate_UpdateMachineProperties.ps1" .\Input.csv
# Get Updated replication Status
#. "$scriptsPath\AzMigrate_UpdateReplicationStatus.ps1" .\Input.csv

# #Start Migration
#. "$scriptsPath\AzMigrate_StartMigration.ps1" .\Input.csv
# Get Updated replication Status
#. "$scriptsPath\AzMigrate_UpdateReplicationStatus.ps1" .\Input.csv

# #Complete Migration
#. "$scriptsPath\AzMigrate_CompleteMigration.ps1" .\Input.csv
# Get Updated replication Status
#. "$scriptsPath\AzMigrate_UpdateReplicationStatus.ps1" .\Input.csv

Write-host "Done!"