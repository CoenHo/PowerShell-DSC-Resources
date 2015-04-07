function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path
	)

	$smbShare = Get-SmbShare -Name $Name -ErrorAction SilentlyContinue
    $changeAccess = @()
    $readAccess = @()
    $fullAccess = @()
    $noAccess = @()
    if ($smbShare -ne $null)
    {
        $smbShareAccess = Get-SmbShareAccess -Name $Name
        $smbShareAccess | %  {
            $access = $_;
            if ($access.AccessRight -eq 'Change' -and $access.AccessControlType -eq 'Allow')
            {
                $changeAccess += $access.AccountName
            }
            elseif ($access.AccessRight -eq 'Read' -and $access.AccessControlType -eq 'Allow')
            {
                $readAccess += $access.AccountName
            }            
            elseif ($access.AccessRight -eq 'Full' -and $access.AccessControlType -eq 'Allow')
            {
                $fullAccess += $access.AccountName
            }
            elseif ($access.AccessRight -eq 'Full' -and $access.AccessControlType -eq 'Deny')
            {
                $noAccess += $access.AccountName
            }
        }
    }
    else
    {
        Write-Verbose "Share with name $Name does not exist"
    } 

	$returnValue =[ordered] @{
		Name = $smbShare.Name
		Path = $smbShare.Path
        Description = $smbShare.Description
		ConcurrentUserLimit = $smbShare.ConcurrentUserLimit
		EncryptData = $smbShare.EncryptData
		FolderEnumerationMode = $smbShare.FolderEnumerationMode	    		
        ShareState = $smbShare.ShareState
        ShareType = $smbShare.ShareType
        ShadowCopy = $smbShare.ShadowCopy
        Special = $smbShare.Special
        ChangeAccess = $changeAccess
        ReadAccess = $readAccess
        FullAccess = $fullAccess
        NoAccess = $noAccess     
        Ensure = if($smbShare) {'Present'} else {'Absent'}
	}

	$returnValue
}

function Set-AccessPermission
{
    [CmdletBinding()]
    Param
    (           
        $ShareName,

        [string[]]
        $UserName,

        [string]
        [ValidateSet('Change','Full','Read','No')]
        $AccessPermission
    )
    $formattedString = '{0}{1}' -f $AccessPermission,'Access'
    Write-Verbose -Message "Setting $formattedString for $UserName"

    if ($AccessPermission -eq 'Change' -or $AccessPermission -eq 'Read' -or $AccessPermission -eq 'Full')
    {
        Grant-SmbShareAccess -Name $Name -AccountName $UserName -AccessRight $AccessPermission -Force
    }
    else
    {
        Block-SmbShareAccess -Name $Name -AccountName $userName -Force
    }
}

function Remove-AccessPermission
{
    [CmdletBinding()]
    Param
    (           
        $ShareName,

        [string[]]
        $UserName,

        [string]
        [ValidateSet('Change','Full','Read','No')]
        $AccessPermission
    )
    $formattedString = '{0}{1}' -f $AccessPermission,'Access'
    Write-Debug -Message "Removing $formattedString for $UserName"

    if ($AccessPermission -eq 'Change' -or $AccessPermission -eq 'Read' -or $AccessPermission -eq 'Full')
    {
        Revoke-SmbShareAccess -Name $Name -AccountName $UserName -Force
    }
    else
    {
        UnBlock-SmbShareAccess -Name $Name -AccountName $userName -Force
    }
}

function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[System.String]
		$Description,

		[System.String[]]
		$ChangeAccess,

		[System.UInt32]
		$ConcurrentUserLimit,

		[System.Boolean]
		$EncryptData,

		[ValidateSet('AccessBased','Unrestricted')]
		[System.String]
		$FolderEnumerationMode,

		[System.String[]]
		$FullAccess,

		[System.String[]]
		$NoAccess,

		[System.String[]]
		$ReadAccess,

		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure
	)

    $psbound  = $psboundparameters


     $psbound.Remove('Debug')
   
    
  
   
	$shareExists = $false
    $smbShare = Get-SmbShare -Name $Name -ErrorAction SilentlyContinue

    Write-Debug 'stop'
    if($smbShare -ne $null)
    {
        Write-Verbose -Message "Share with name $Name exists"
        $shareExists = $true
    }
    
    if ($Ensure -eq 'Present')
    {
    
        
        if ($shareExists -eq $false)
        {
            
                
 



            $psbound.Remove('Ensure')
            Write-Verbose "Creating share $Name to ensure it is Present"
            New-SmbShare -Name $name -Path $path


             #Assigning Perrsmison

            if ($psbound.ContainsKey('ChangeAccess'))
            {
                $changeAccessValue = $psbound['ChangeAccess']
                $psbound.Remove('ChangeAccess')
            }
            if ($psbound.ContainsKey('ReadAccess'))
            {
                $readAccessValue = $psbound['ReadAccess']
                $psbound.Remove('ReadAccess')
            }
            if ($psbound.ContainsKey('FullAccess'))
            {
                $fullAccessValue = $psbound['FullAccess']
                $psbound.Remove('FullAccess')
            }
            if ($psbound.ContainsKey('NoAccess'))
            {
                $noAccessValue = $psbound['NoAccess']
                $psbound.Remove('NoAccess')
            }
            
            # Use Set-SmbShare for performing operations other than changing access
            $psbound.Remove('Ensure')
            $psbound.Remove('Path')
            Set-SmbShare @psbound -Force
            
            # Use *SmbShareAccess cmdlets to change access
            $smbshareAccessValues = Get-SmbShareAccess -Name $Name
            if ($ChangeAccess -ne $null)
            {
                # Blow off whatever is in there and replace it with this list
                $smbshareAccessValues | ? {$_.AccessControlType  -eq 'Allow' -and $_.AccessRight -eq 'Change'} `
                                      | % {
                                            Remove-AccessPermission -ShareName $Name -UserName $_.AccountName -AccessPermission Change
                                          }
                                  
                $changeAccessValue | % {
                                        Set-AccessPermission -ShareName $Name -AccessPermission 'Change' -Username $_
                                       }
            }
            $smbshareAccessValues = Get-SmbShareAccess -Name $Name
            if ($ReadAccess -ne $null)
            {
                # Blow off whatever is in there and replace it with this list
                $smbshareAccessValues | ? {$_.AccessControlType  -eq 'Allow' -and $_.AccessRight -eq 'Read'} `
                                      | % {
                                            Remove-AccessPermission -ShareName $Name -UserName $_.AccountName -AccessPermission Read
                                          }

                $readAccessValue | % {
                                       Set-AccessPermission -ShareName $Name -AccessPermission 'Read' -Username $_                        
                                     }
            }
            $smbshareAccessValues = Get-SmbShareAccess -Name $Name
            if ($FullAccess -ne $null)
            {
                # Blow off whatever is in there and replace it with this list
                $smbshareAccessValues | ? {$_.AccessControlType  -eq 'Allow' -and $_.AccessRight -eq 'Full'} `
                                      | % {
                                            Remove-AccessPermission -ShareName $Name -UserName $_.AccountName -AccessPermission Full
                                          }

                $fullAccessValue | % {
                                        Set-AccessPermission -ShareName $Name -AccessPermission 'Full' -Username $_                        
                                     }
            }
            $smbshareAccessValues = Get-SmbShareAccess -Name $Name
            if ($NoAccess -ne $null)
            {
                # Blow off whatever is in there and replace it with this list
                $smbshareAccessValues | ? {$_.AccessControlType  -eq 'Deny'} `
                                      | % {
                                            Remove-AccessPermission -ShareName $Name -UserName $_.AccountName -AccessPermission No
                                          }
                $noAccessValue | % {
                                      Set-AccessPermission -ShareName $Name -AccessPermission 'No' -Username $_
                                   }


        }
        }else
        {

     
       if($OtherParamResult -ccontains "False" -and $issuefound ) {

            # Need to call either Set-SmbShare or *ShareAccess cmdlets
            if ($psbound.ContainsKey('ChangeAccess'))
            {
                $changeAccessValue =$psbound['ChangeAccess']
               $psbound.Remove('ChangeAccess')
            }
            if ($psbound.ContainsKey('ReadAccess'))
            {
                $readAccessValue =$psbound['ReadAccess']
               $psbound.Remove('ReadAccess')
            }
            if ($psbound.ContainsKey('FullAccess'))
            {
                $fullAccessValue =$psbound['FullAccess']
               $psbound.Remove('FullAccess')
            }
            if ($psbound.ContainsKey('NoAccess'))
            {
                $noAccessValue =$psbound['NoAccess']
               $psbound.Remove('NoAccess')
            }
            
            # Use Set-SmbShare for performing operations other than changing access
           $psbound.Remove('Ensure')
           $psbound.Remove('Path')
            Set-SmbShare @psbound -Force
            
       


      if ($issuefound){

        $smbshareAccessValues = Get-SmbShareAccess -Name $Name

   $smbshareAccessValues |  % { Remove-AccessPermission -ShareName $Name -UserName $_.AccountName -AccessPermission Change}
    

        } else {

            # Use *SmbShareAccess cmdlets to change access
            $smbshareAccessValues = Get-SmbShareAccess -Name $Name
            if ($ChangeAccess -ne $null)
            {
                # Blow off whatever is in there and replace it with this list
                $smbshareAccessValues | ? {$_.AccessControlType  -eq 'Allow' -and $_.AccessRight -eq 'Change'} `
                                      | % {
                                            Remove-AccessPermission -ShareName $Name -UserName $_.AccountName -AccessPermission Change
                                          }
                                  
                $changeAccessValue | % {
                                        Set-AccessPermission -ShareName $Name -AccessPermission 'Change' -Username $_
                                       }
            }
            $smbshareAccessValues = Get-SmbShareAccess -Name $Name
            if ($ReadAccess -ne $null)
            {
                # Blow off whatever is in there and replace it with this list
                $smbshareAccessValues | ? {$_.AccessControlType  -eq 'Allow' -and $_.AccessRight -eq 'Read'} `
                                      | % {
                                            Remove-AccessPermission -ShareName $Name -UserName $_.AccountName -AccessPermission Read
                                          }

                $readAccessValue | % {
                                       Set-AccessPermission -ShareName $Name -AccessPermission 'Read' -Username $_                        
                                     }
            }
            $smbshareAccessValues = Get-SmbShareAccess -Name $Name
            if ($FullAccess -ne $null)
            {
                # Blow off whatever is in there and replace it with this list
                $smbshareAccessValues | ? {$_.AccessControlType  -eq 'Allow' -and $_.AccessRight -eq 'Full'} `
                                      | % {
                                            Remove-AccessPermission -ShareName $Name -UserName $_.AccountName -AccessPermission Full
                                          }

                $fullAccessValue | % {
                                        Set-AccessPermission -ShareName $Name -AccessPermission 'Full' -Username $_                        
                                     }
            }
            $smbshareAccessValues = Get-SmbShareAccess -Name $Name
            if ($NoAccess -ne $null)
            {
                # Blow off whatever is in there and replace it with this list
                $smbshareAccessValues | ? {$_.AccessControlType  -eq 'Deny'} `
                                      | % {
                                            Remove-AccessPermission -ShareName $Name -UserName $_.AccountName -AccessPermission No
                                          }
                $noAccessValue | % {
                                      Set-AccessPermission -ShareName $Name -AccessPermission 'No' -Username $_
                                   }
            }






            }#elseesle




                                            } ## Closing issue found and parama founds
                                            else {
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            





























                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            }## Closing not found and parama founds











        }
    }
    else 
    {
        Write-Verbose "Removing share $Name to ensure it is Absent"
        Remove-SmbShare -name $Name -Force
    }
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[System.String]
		$Description,

		[System.String[]]
		$ChangeAccess,

		[System.UInt32]
		$ConcurrentUserLimit,

		[System.Boolean]
		$EncryptData,

		[ValidateSet('AccessBased','Unrestricted')]
		[System.String]
		$FolderEnumerationMode,

		[System.String[]]
		$FullAccess,

		[System.String[]]
		$NoAccess,

		[System.String[]]
		$ReadAccess,

		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure = 'Present'
	)
    $testResult = $false
    $PSBound   =    $PSBoundParameters
    $PSBound.Remove('Debug') | Out-Null
    $PSBound.Remove('Verbose') | Out-Null
    $PSBound.Remove('DependsOn') | Out-Null
    
    


    $share = Get-SmbShare -Name $Name -ErrorAction SilentlyContinue -ErrorVariable ev
    Write-Debug 'stop'
    



## getting current perrmisions assigned to the shares 

$smbShare = Get-SmbShare -Name $Name -ErrorAction SilentlyContinue
    $CurrentchangeAccess = @()
    $CurrentreadAccess = @()
    $CurrentfullAccess = @()
    $CurrentnoAccess = @()
    if ($smbShare -ne $null)
    {
        $smbShareAccess = Get-SmbShareAccess -Name $Name
        $smbShareAccess | %  {
            $access = $_;
            if ($access.AccessRight -eq 'Change' -and $access.AccessControlType -eq 'Allow')
            {
                $CurrentchangeAccess += $access.AccountName
            }
            elseif ($access.AccessRight -eq 'Read' -and $access.AccessControlType -eq 'Allow')
            {
                $CurrentreadAccess += $access.AccountName
            }            
            elseif ($access.AccessRight -eq 'Full' -and $access.AccessControlType -eq 'Allow')
            {
                $CurrentfullAccess += $access.AccountName
            }
            elseif ($access.AccessRight -eq 'Full' -and $access.AccessControlType -eq 'Deny')
            {
                $CurrentnoAccess += $access.AccountName
            }
        }
    }
    else
    {
        Write-Verbose "Share with name $Name does not exist"
        
    } 



$CurrentConfiguration = @{
		Name = $smbShare.Name
		Path = $smbShare.Path
        Description = $smbShare.Description
		ConcurrentUserLimit = $smbShare.ConcurrentUserLimit
		EncryptData = $smbShare.EncryptData
		FolderEnumerationMode = $smbShare.FolderEnumerationMode	    		
        ChangeAccess = $CurrentchangeAccess
        ReadAccess = $CurrentreadAccess
        FullAccess = $CurrentfullAccess
        NoAccess = $CurrentnoAccess     
        Ensure = if($smbShare) {'Present'} else {'Absent'}
	}

 

$SpecifiedParameters = @{
		Name = $Name
		Path = $Path
        Description = $Description
		ChangeAccess = $ChangeAccess
		ConcurrentUserLimit = $ConcurrentUserLimit
		EncryptData = $EncryptData    		
        FolderEnumerationMode = $FolderEnumerationMode
        FullAccess = $FullAccess
        NoAccess = $NoAccess
        ReadAccess = $ReadAccess    
        Ensure = $Ensure
	}


## Counting Numbers for loop  FullAccess 

if ($CurrentConfiguration.fullaccess.Count -gt $PSBound.fullaccess.count)
{
$numberfullaccess = $CurrentConfiguration.fullaccess.Count

}else {


$numberfullaccess = $PSBound.fullaccess.count


}

## Counting Numbers for loop ReadAccess

if ($CurrentConfiguration.readaccess.Count -gt $PSBound.readaccess.count)
{
$numberreadaccess = $CurrentConfiguration.readaccess.Count

}else {


$numberreadaccess = $PSBound.readaccess.count


}

## Counting Numbers for loop ChangeAccess

if ($CurrentConfiguration.ChangeAccess.Count -gt $PSBound.ChangeAccess.count)
{
$numberChangeAccess = $CurrentConfiguration.ChangeAccess.Count

}else {


$numberChangeAccess = $PSBound.ChangeAccess.count


}

## Counting Numbers for loop NOAccess

if ($CurrentConfiguration.noaccess.Count -gt $PSBound.noaccess.count)
{
$numbernoaccess = $CurrentConfiguration.noaccess.Count

}else {


$numbernoaccess = $PSBound.noaccess.count


}

## looping through assigned perrmisions 	

  $TestingAccess = @{}  
  $TestingAccess1 = @()

If   ($PSBound.ContainsKey('noaccess')){

    
    for ($i = 0; $i -lt $numbernoaccess; $i++)
    { 

     $res =  ($PSBound.noaccess   -contains    $CurrentConfiguration.NoAccess[$i]).ToString()  

      $user =  $CurrentConfiguration.NoAccess[$i]
      
      if($user){

     $TestingAccess.add($user,$res)
      
      }else {

      $TestingAccess1 += $res

      }
      
     }
        
    }#end IF 
    


If   ($PSBound.ContainsKey('fullaccess')){

     for ($i = 0; $i -lt $numberfullaccess ; $i++)
    { 

     $res =  ($PSBound.fullaccess  -contains    $CurrentConfiguration.fullaccess[$i]).ToString()  

     $user = $CurrentConfiguration.fullaccess[$i]

     if($user){

     $TestingAccess.add($user,$res)
      
      }else {

      $TestingAccess1 += $res

      }

        
    }




}#end IF


If   ($PSBound.ContainsKey('readaccess')){

     for ($i = 0; $i -lt $numberreadaccess; $i++)
    { 

     $res =  ($PSBound.readaccess   -contains    $CurrentConfiguration.readaccess[$i]).ToString() 

     $user = $CurrentConfiguration.readaccess[$i]


      if($user){

     $TestingAccess.add($user,$res)
      
      }else {

      $TestingAccess1 += $res

      } 

     }   
    
    } #end IF

If   ($PSBound.ContainsKey('ChangeAccess')){

     for ($i = 0; $i -lt $numberChangeAccess; $i++)
    { 

     $res =  ($PSBound.ChangeAccess   -contains    $CurrentConfiguration.ChangeAccess[$i]).ToString() 

     $user = $CurrentConfiguration.ChangeAccess[$i]

     if($user){

     $TestingAccess.add($user,$res)
      
      }else {

      $TestingAccess1 += $res

      } 

     }   
    
    } #end IF


## creating the object and Assigning Global Variable for Set-TargetResources Function  


$global:issuefound = ($TestingAccess.GetEnumerator() | Where-Object { $_.value -eq "False"}).name
$issuefounded = ($TestingAccess.GetEnumerator() | Where-Object { $_.value -eq "False"}).value



## testing Other Parameters 

$list1 = $PSBound.Keys.Split('"') 

foreach ($l in $list1) {

$SpecifiedParameters.Remove($l)

}



if ($SpecifiedParameters.ContainsKey('EncryptData')){

$SpecifiedParameters.Remove('EncryptData')
}



if ($SpecifiedParameters.ContainsKey('ConcurrentUserLimit')){

$SpecifiedParameters.Remove('ConcurrentUserLimit')
}

$yes = $SpecifiedParameters.keys -join ' ' -split ' '


$configparam = foreach ($ye in $yes) {  if($SpecifiedParameters[$ye]){'False'}else{'True'} }





## removing Keys from PSBoundParameters

 $PSBound.Remove('fullaccess') | Out-Null
 $PSBound.Remove('readaccess') | Out-Null
 $PSBound.Remove('noaccess') | Out-Null
 $PSBound.Remove('ChangeAccess') | Out-Null



## Testing other parameters if they are correct 

$PSBoundParameter = $PSBound.Keys.Split('"')


$OtherParamResult  = @()


for ($i = 0; $i -lt $PSBoundParameter.Count ; $i++)
{ 
 
 $test1 = ($PSBound[$PSBoundParameter[$i]]-join ' ').ToString()
 $test2  = ($CurrentConfiguration[$PSBoundParameter[$i]]-join ' ' ).ToString()

 $result = ($test1 -eq $test2 ).ToString()
 
 
 $OtherParamResult += $result
 
    
}

## assigning Global Variable for Set-TargetResources

$global:OtherParamResult = $OtherParamResult







$finaltest =$OtherParamResult + $issuefounded + $configparam  + $TestingAccess1

Write-Verbose 'Testing perrmisions '

    if ($Ensure -eq 'Present')
    {
        if ($share -eq $null)
        {
            $testResult = $false
        }
        elseif ($share -ne $null -and $finaltest -contains 'false' )



        {

            Write-Verbose 'Reporting FALSE There is Something wrong'

            $testResult = $false

        }







        else
        {
            Write-Verbose 'ALL GOOD With Perrmsions and Share'

            $testResult = $true


        }
    }



    else
    {
        if ($share -eq $null)
        {
            Write-Verbose 'ALL GOOD'

            $testResult = $true
        }
        else
        {
             Write-Verbose 'Share Needs to be Removed'

            $testResult = $false
        }
    }

	$testResult
}

Export-ModuleMember -Function *-TargetResource



