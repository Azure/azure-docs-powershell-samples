#Migration of VMware VMs using Azure Site Recovery

These scripts help you automate the migration of large number of VMs to Azure using Azure Site Recovery (ASR). The scripts leverage ASR PowerShell documented [here](https://docs.microsoft.com/azure/site-recovery/vmware-azure-disaster-recovery-powershell).

## Current Limitations:
- The script works only for VMware to Azure scenario
- It currently supports migration to non-managed disks only
- Supports migration to Standard disks only
- Supports specifying the static IP address only for the primary NIC of the target VM
- Does not support specifying Azure Hybrid Benefit related property

##How does it work?

###Pre-requisites
Before you get started, the script requires you to do the following:
- Ensure that the Site Recovery vault is created
- Ensure that the Configuration Server is installed in the on-premises environment (and the Process Server) and the vault is able to discover the environment using the vCenter credentials
- Ensure that a Replication Policy is created and associated with the Configuration Server
- Ensure that you have added the VM admin account to the config server (that will be used to replicate the on-prem VMs)
- Ensure that the target artefacts in Azure are created
    - Target Resource Group
    - Target Storage Account (and its Resource Group)
    - Target Virtual Network for failover (and its Resource Group)
    - Target Subnet
    - Target Virtual Network for Test failover (and its Resource Group)
    - Availability Set (if needed)
    - Target Network Security Group and its Resource Group
  - Ensure that you have decided on the properties of the target VM
    - Target VM name
    - Target VM size in Azure (can be decided using Azure Migrate assessment)
    - Private IP Address of the primary NIC in the VM

###CSV Input file
Once you have all the pre-requisites completed, you need to create a CSV file which has data for each on-premises machines that you want to migrate. The input CSV must have a header line with specific names and after that must provide migration values according to these header fields for each machine to be migrated. All the scripts are designed to work of off the same CSV file. A sample CSV template is available in the folder for your reference.

- [Sample CSV template](input_template.csv)

###Script execution
Once the CSV is ready, you can execute the following steps to perform migration of the on-premises VMs:

**Step #** | **Script Name** | **Description**
--- | --- | ---
1 | asr_migration.ps1 | Enable replication for all the VMs listed in the csv, creates a CSV output with the job details for each VM
2 | asr_migration_status.ps1 | Checks the status of replication and creates a csv with the status for each VM
3 | asr_updateproperties.ps1 | Once the VMs are replicated/protected, use this script to update the target properties of the VM (Compute and Network properties)
4 | asr_properties_check.ps1 | Verifies if the properties are appropriately updated
5 | asr_test_failover.ps1 |  Starts the test failover of the VMs listed in the csv, creates a CSV output with the job details for each VM
6 | asr_cleanup_failover.ps1 | Once you manually validate the VMs that were test failed-over, you can use this script to clean up the test failover VMs
7 | asr_failover.ps1 | Perform an unplanned failover for the VMs listed in the csv, creates a CSV output with the job details for each VM. The script does not shutdown the on-prem VMs before triggering the failover, for application consistency, it is recommended that you manually shut down the VMs before executing the script.
8 | asr_complete.ps1 | Performs a commit operation on the VMs and deletes the ASR entities
9 | asr_post_failover.ps1 | If you plan to assign network security groups to the NICs post-failover, you can use this script to do that. It assigns one NSG to one NIC in the target VM.
