Run a custom script inside a VM failed over using an ASR Recovery Plan
======================================================================

            

 

 This runbook provides a way to run a script inside the guest virtual machine using custom script extension
 This script is to be used with VMs that are failed voery by an ASR recoery plan. Since the VM is provisioned dynamically in a cloud service you need to specify the VM   Guid of the VM so that the script can correctly
 reference it
 Example: Changing connection string after failing over a frontend virtual machine
 This is a sample script, you can modify based on your requirements

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
