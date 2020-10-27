<#
.SYNOPSIS
    Runbook to run a custom script inside an Azure Virtual Machine
    This script needs to be used along with recovery plans in Azure Site Recovery.

.DESCRIPTION
    This runbook provides a way to run a script inside the guest virtual machine using custom script extension
    This script is to be used with VMs that are failed over by recovery plan. Since the VM is provisioned dynamically in the 
    cloud service you need to specify the VMM VM GUID of the VM so that the script can correctly reference it.
    Example : Changing connection string after failing over frontend virtual machine
     
.DEPENDENCIES
    Azure VM agent should be installed in the VM before it is executed
    If it is not already installed install it inside the VM from http://aka.ms/vmagentwin
    Script that needs to run inside the virtual machine should already be uploaded in a storage account
    Use the following commands to upload the script
    
    $context = New-AzureStorageContext -StorageAccountName "ScriptStorageAccountName" -StorageAccountKey "ScriptStorageAccountKey"
    Set-AzureStorageBlobContent -Blob "script.ps1" -Container "script-container" -File "ScriptLocalFilePath" -context $context
   
    Make sure that you specify the name and cloud service name of the VM into which the script will be run
    $VMRoleName and $VMServiceName should be set to a string with the required value

    Make sure you specify the storage container name and the script name. 
    $ScriptContainer and $ScriptName should be set to a string with the required value

    Make sure you specify the aruments to be passed to the script in variable $Args
    Example: $Args = "-Argument1 value1 -Argument2 value2"     
   
.ASSETS
    Add Assets 'ScriptStorageAccountName' and 'ScriptStorageAccountKey' in the azure automation account
    You can choose to encrtypt these assets
    ScriptStorageAccountName: Name of the storage account where the script is stored
    ScriptStorageAccountKey: Key for the storage account where the script is stored

.PARAMETER RecoveryPlanContext
    RecoveryPlanContext is the only parameter you need to define.
    This parameter gets the failover context from the recovery plan. 

.NOTES
	Author: Prateek Sharma - pratshar@microsoft.com 
	Last Updated: 29/04/2015   
#>

workflow RunScriptInFailedoverVM
{
    param (
        [Object]$RecoveryPlanContext
    )

    $Cred = Get-AutomationPSCredential -Name 'AzureCredential'

    # Connect to Azure
    $AzureAccount = Add-AzureAccount -Credential $Cred
    $AzureSubscriptionName = Get-AutomationVariable –Name 'AzureSubscriptionName'
    Select-AzureSubscription -SubscriptionName $AzureSubscriptionName
    
    #Specify the VM onto which you want to act upon
    $VMGUID = ""
    #Read the VM GUID from the context
    $VMContext = $RecoveryPlanContext.VmMap.$VMGUID
    
    $VMRoleName = $VMContext.RoleName
    $VMServiceName = $VMContext.CloudServiceName

    
    #Provide the storage account name and the storage account key information
    $StorageAccountName = Get-AutomationVariable –Name 'ScriptStorageAccountName'
    $StorageAccountKey  =  Get-AutomationVariable –Name 'ScriptStorageAccountKey'
    
    #Provide the script details
    $ScriptContainer = ""
    $ScriptName = ""
    
    InLineScript
    {
       $context = New-AzureStorageContext -StorageAccountName $Using:StorageAccountName `
                  -StorageAccountKey $Using:StorageAccountKey;
       $sasuri = New-AzureStorageBlobSASToken -Container $Using:ScriptContainer `
                 -Blob $Using:ScriptName -Permission r -FullUri -Context $context
       
       $AzureVM = Get-AzureVM -ServiceName $Using:VMServiceName -Name $Using:VMRoleName      
         
       Write-Output "UnInstalling custom script extension"
       Set-AzureVMCustomScriptExtension -Uninstall -ReferenceName CustomScriptExtension -VM $AzureVM | Update-AzureVM
         
       Write-Output "Installing custom script extension"
       Set-AzureVMExtension -ExtensionName CustomScriptExtension -VM $AzureVM -Publisher Microsoft.Compute -Version 1.4 | Update-AzureVM   
                            
       Write-output "Running script on the VM"
       Set-AzureVMCustomScriptExtension -VM $AzureVM -FileUri $sasuri -Run $Using:ScriptName | Update-AzureVM
       
       # If your script requires argument the comment the line above and use the following two lines
       #$Args = ""           
       #Set-AzureVMCustomScriptExtension -VM $AzureVM -FileUri $sasuri -Run $Using:ScriptName -Argument $Args | Update-AzureVM
       
       Write-output "Completed running script on the VM"                
    }
    
}