﻿
DATA localizedData
{
    # same as culture = "en-US"
ConvertFrom-StringData @'    
    VMNameAndManagementTogether=VMName cannot be provided when ManagementOS is set to True.
    MustProvideVMName=Must provide VMName parameter when ManagementOS is set to False.
    GetVMNetAdapter=Getting VM Network Adapter information.
    FoundVMNetAdapter=Found VM Network Adapter.
    NoVMNetAdapterFound=No VM Network Adapter found.
    StaticAndDynamicTogether=StaticMacAddress and DynamicMacAddress parameters cannot be provided together.
    ModifyVMNetAdapter=VM Network Adapter exists with different configuration. This will be modified.
    EnableDynamicMacAddress=VM Network Adapter exists but without Dynamic MAC address setting.
    EnableStaticMacAddress=VM Network Adapter exists but without static MAC address setting.
    PerformVMNetModify=Performing VM Network Adapter configuration changes.
    CannotChangeHostAdapterMacAddress=VM Network adapter in configuration is a host adapter. Its configuration cannot be modified.
    AddVMNetAdapter=Adding VM Network Adapter.
    RemoveVMNetAdapter=Removing VM Network Adapter.
    VMNetAdapterExistsNoActionNeeded=VM Network Adapter exists with requested configuration. No action needed.
    VMNetAdapterDoesNotExistShouldAdd=VM Network Adapter does not exist. It will be added.
    VMNetAdapterExistsShouldRemove=VM Network Adapter Exists. It will be removed.
    VMNetAdapterDoesNotExistNoActionNeeded=VM Network adapter does not exist. No action needed.
'@
}



enum Ensure 
{ 
    Absent 
    Present 
}

[DscResource()]
class VMNetworkAdapter{

    [DscProperty(Key)]
    [string]$AdapterName
  
    [DscProperty(Mandatory)]
    [Bool] $ManagementOS
    
    [DscProperty(Mandatory)]
    [String] $SwitchName

    [DscProperty()]
    [String] $VMName

    [DscProperty()]
    [Bool] $DynamicMacAddress

    [DscProperty()]
    [String] $StaticMacAddress

    [Ensure] $Ensure

    #Replaces Get-TargetResource





    [VMNetworkAdapter] Get() 
    {

            $vmAdapterConfig =[hashtable]::new()
            




    }

    #Replaces Test-TargetResource
    [bool] Test()
    {

    }

    #Replaces Set-TargetResource
    [void] Set()
    {

    }


}