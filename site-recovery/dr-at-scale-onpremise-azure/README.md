# Scale migration of VMs using Azure Site Recovery

These scripts help you automate the replication of large number of VMs to Azure using Azure Site Recovery (ASR). These scripts can be used to protect VMware, VMs and physical servers to Azure.The scripts leverage ASR PowerShell documented [here](https://docs.microsoft.com/azure/site-recovery/vmware-azure-disaster-recovery-powershell).

## Current Limitations:
- Supports replication to Standard disks only
- Supports specifying the static IP address only for the primary NIC of the target VM
- The scripts do not take Azure Hybrid Benefit related inputs, you need to manually update the properties of the replicated VM in the portal

## How does it work?

### Pre-requisites
Before you get started, you need to do the following:
- Ensure that the Site Recovery vault is created in your Azure subscription
- Ensure that the Configuration Server and Process Server are installed in the source environment and the vault is able to discover the environment
- Ensure that a Replication Policy is created and associated with the Configuration Server
- Ensure that you have added the VM admin account to the config server (that will be used to replicate the on-prem VMs)
- Ensure that the target artifacts in Azure are created
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

### CSV Input file
Once you have all the pre-requisites completed, you need to create a CSV file which has data for each source machine that you want to migrate. The input CSV must have a header line with the input details and a row with details for each machine that needs to be protected. All the scripts are designed to work on the same CSV file. A sample CSV template is available in the folder for your reference.

- [Input CSV template](input_template.csv)
- [Sample CSV](samplecsv.csv)

### Script execution
Once the CSV is ready, you can execute the following steps to perform migration of the on-premises VMs:

**Step #** | **Script Name** | **Description**
--- | --- | ---
1 | asr_startreplication.ps1 | Enable replication for all the VMs listed in the csv, the script creates a CSV output with the job details for each VM
2 | asr_replicationstatus.ps1 | Check the status of replication, the script creates a csv with the status for each VM
3 | asr_updateproperties.ps1 | Once the VMs are replicated/protected, use this script to update the target properties of the VM (Compute and Network properties)
4 | asr_propertiescheck.ps1 | Verify if the properties are appropriately updated
5 | asr_testfailover.ps1 |  Start the test failover of the VMs listed in the csv, the script creates a CSV output with the job details for each VM
6 | asr_cleanuptestfailover.ps1 | Once you manually validate the VMs that were test failed-over, you can use this script to clean up the test failover VMs
7 | asr_failover.ps1 | Perform an unplanned failover for the VMs listed in the csv, the script creates a CSV output with the job details for each VM. The script does not shutdown the on-prem VMs before triggering the failover, for application consistency, it is recommended that you manually shut down the VMs before executing the script.

