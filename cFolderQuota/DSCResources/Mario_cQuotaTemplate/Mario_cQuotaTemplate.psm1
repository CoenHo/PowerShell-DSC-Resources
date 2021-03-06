

Function Get-TargetResource
{
          [OutputType([Hashtable])]
          [CmdletBinding()]
            param
            (
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [ValidateSet('Present','Absent')]
            [string]
            $Ensure = 'Present',

            [string]
            $Description,
            
            [Parameter(Mandatory=$true)]
            [int64]
            $Size,

            [Boolean]
            $SoftLimit,

            [string]
            $MailTo,

            [string]
            $Subject,

            [int64]
            $Percentage,

            [string]
            $Body


            )

         Write-Verbose "Testing Quota Template Configuration" 

    $findQuota = Get-FsrmQuotaTemplate $name -ErrorAction SilentlyContinue

    $returnValue = @{
		Name = $findQuota.Name
		Size = $findQuota.Size
        Description = $findQuota.Description
		SoftLimit = If($SoftLimit){"True"} else {"False"}
		MailTo = $findQuota.Threshold.Action.MailTo
		Body = $findQuota.Threshold.Action.Body    		
        Percentage = $findQuota.Threshold.Percentage
        Subject = $findQuota.Threshold.Action.Subject   
        Ensure = if($findQuota) {"Present"} else {"Absent"}
	}

	$returnValue



          
}

Function Test-TargetResource
{
          [OutputType([boolean])]
          [CmdletBinding()]
            param
            (
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [ValidateSet('Present','Absent')]
            [string]
            $Ensure = 'Present',

            [string]
            $Description,
            
            [Parameter(Mandatory=$true)]
            [int64]
            $Size,

            [Boolean]
            $SoftLimit,

            [string]
            $MailTo,

            [string]
            $Subject,

            [int64]
            $Percentage,

            [string]
            $Body

            )

     If($MailTo -eq 'Owner'){

                $MailTo = "[Source Io Owner Email]"
                $PSBoundParameters.Remove("MailTo")| Out-Null
                $PSBoundParameters.add("MailTo",$MailTo)| Out-Null

                }
    
    
    $test   =    $PSBoundParameters
    $test.Remove("Debug") | Out-Null
    $test.Remove("Verbose") | Out-Null
    $test.Remove("DependsOn") | Out-Null

  
    Write-Verbose "Testing Quota Template" 

    $findQuota = Get-FsrmQuotaTemplate $name -ErrorAction SilentlyContinue

    $returnValue = [ordered]@{
		Name = $findQuota.Name
		Size = $findQuota.Size
        Description = $findQuota.Description
		SoftLimit = $findQuota.SoftLimit
		MailTo = $findQuota.Threshold.Action.MailTo
		Body = $findQuota.Threshold.Action.Body    		
        Percentage = $findQuota.Threshold.Percentage
        Subject = $findQuota.Threshold.Action.Subject   
        Ensure = if($findQuota) {"Present"} else {"Absent"}
	}

## Testing Keys 

                                $list = $test.Keys.Split("""")

                                $CompareResults  = @()


                                for ($i = 0; $i -lt $list.Count ; $i++)
                                { 
 
                                 $nice1 = ($test[$list[$i]]-join " ").ToString().TrimEnd("")
                                 $nice  = ($returnValue[$list[$i]]-join " " ).ToString().TrimEnd("")

                                 $rezultat = ($nice -eq $nice1).ToString()
 


                                 $CompareResults += $rezultat
 
    
                                }

## Testing Keys

    if($ensure -eq "Present")
    {
           if ($findQuota){

                    if ($CompareResults -contains "false"){

                         Write-Verbose " QuotaTemplate $name not in the right state"


            return $false


            }else  #ifclose
            {


            Write-Verbose "QuotaTemplate  $name Exist and its in the right state"

            return $true



            }

           }else {



           Write-Verbose "QuotaTemplate  $name doesn't exist" 

           return $false



           }




    }
    
    else {

            if ($findQuota) {


            Write-Verbose "QuotaTemplate $name  Exist , while it should not be "

            return $false


            }else {

            Write-Verbose " QuotaTemplate $name  doesn't Exist , Nothing to Configure "
            
            return $true


            }


    }


}



Function Set-TargetResource
{
  
          [CmdletBinding()]
            param
            (
            [Parameter(Mandatory=$true)]
            [string]
            $name,

            [ValidateSet('Present','Absent')]
            [string]
            $Ensure = 'Present',

            [string]
            $Description,
            
            [Parameter(Mandatory=$true)]
            [int64]
            $Size,

            [Boolean]
            $SoftLimit,

            [string]
            $MailTo,

            [string]
            $Subject,

            [int64]
            $Percentage,

            [string]
            $Body

        

            )
    Write-Debug "nice"


                If($MailTo -eq 'Owner'){

                $MailTo = "[Source Io Owner Email]"


                }
        

            $findQuota = Get-FsrmQuotaTemplate $name -ErrorAction SilentlyContinue

            Write-Verbose " Testing Configuration "
            
            If ($Ensure -eq "Present"){

     
            if(-not $findQuota) { #if findQuota
            
            if($SoftLimit){

            #if Quota exist then change only Configuration
        
            Write-Verbose "Creating new Quota Template $name with Soft Limit "

                    $Action = New-FsrmAction -Type Email -MailTo $MailTo -Subject $Subject -Body  $Body 
            
                    $Threshold = New-FsrmQuotaThreshold -Percentage $Percentage -Action $Action 
                    
                    New-FsrmQuotaTemplate -Name $name -Description $Description -Size  $Size -Threshold $Threshold -SoftLimit | Out-Null
                        
             
                 
                    }else {
                     
           Write-Verbose "Creating new Quota Template $name with Hard Limit "

                $Action = New-FsrmAction -Type Email -MailTo $MailTo -Subject $Subject -Body  $Body
            
                $Threshold = New-FsrmQuotaThreshold -Percentage $Percentage -Action $Action 

                New-FsrmQuotaTemplate -Name $name -Description $Description -Size  $Size -Threshold $Threshold   | Out-Null



            }

            }else {

                If($SoftLimit) {

 Write-Verbose "Changing Quota Template $name "
        
        $Action = New-FsrmAction -Type Email -MailTo $MailTo -Subject $Subject -Body  $Body
        $Threshold = New-FsrmQuotaThreshold -Percentage $Percentage -Action $Action 
        set-FsrmQuotaTemplate -Name $name -Description $Description -Size  $Size -Threshold $Threshold -SoftLimit -UpdateDerived | Out-Null
                }else {

 Write-Verbose "Changing Quota Template $name "

        $Action = New-FsrmAction -Type Email -MailTo $MailTo -Subject $Subject -Body  $Body
        $Threshold = New-FsrmQuotaThreshold -Percentage $Percentage -Action $Action 
        set-FsrmQuotaTemplate -Name $name -Description $Description -Size  $Size -Threshold $Threshold  -UpdateDerived | Out-Null

                }


            }#findQuota Close




            
            
            }else {#absent Close

            if ($findQuota) {

            Write-Verbose "Deleting  $name Quota"


            Remove-FsrmQuotaTemplate  -Name $name -Confirm:$false | Out-Null
           
           }else {


            Write-Verbose "Nothing to Delete , Its All good"



           }



            }




}



Export-ModuleMember -Function *-TargetResource

