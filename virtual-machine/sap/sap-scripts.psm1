
function Update-SAPASCSSCSProfile{
<#
.SYNOPSIS 
Update-SAPASCSSCSProfile updates SAP ABAP ASCS or SAP Java SCS profile as well as DEFAULT.PFL to new ASCS/SCS hostname and new GLOBALHOST name. 

.DESCRIPTION
Update-SAPASCSSCSProfile updates SAP ABAP ASCS or SAP Java SCS profile as well as DEFAULT.PFL to new ASCS/SCS hostname and new GLOBALHOST name. 

You can specify path to original ASCS/SCS profile file using local or UNC path. From the profile name will be read old ASCS / SCS hostname.

If you specify local path, ASCS/SCS profile parameters are set to use local path. In this case clustered SAP ASCS/SCS instance and SOFS (Scale Out File Server) are runnign on the SAME cluster.  

Similary, if you specify UNC path ACS/SCS profile parameters are set to use UNC path. In this case clustered SAP ASCS/SCS instance and SOFS (Scale Out File Server) are runnign on DIFFERENT clusters.  

.PARAMETER PathToAscsScsInstanceProfile 
The local or UNC path to SAP ASCS/SCS profile. 

.PARAMETER NewASCSHostName 
New SAP ASCS/SCS host name (Message and Enqueue Server host name). 

.PARAMETER NewSAPGlobalHostName 
New SAP GLOBALHOST host name. 

.EXAMPLE 
Update-SAPASCSSCSProfile -PathToAscsScsInstanceProfile \\ja1global\sapmnt\JA1\SYS\profile\JA1_SCS00_ja1-ascs-1 -NewASCSHostName ja1scs -NewSAPGlobalHostName ja1global

Update SAP Java SCS instance to new  SCS host 'ja1scs', and new GLOBALHOST 'ja1global'. SOFS is reached using 'ja1global' hostname. SAP SCS instance and SOFS are runnign on DIFFERENT clusters.
SAP SCS instance is configured to access SAP GLOBALHOST using UNC file share path e.g. \\ja1global\sapmnt\JA1\SYS\....

.EXAMPLE 
Update-SAPASCSSCSProfile -PathToAscsScsInstanceProfile C:\usr\sap\SF1\SYS\profile\SF1_ASCS00_sf1-sofs1 -NewASCSHostName sf1ascs -NewSAPGlobalHostName sf1global -Verbose

Update SAP ASCS instance to new ASCS host 'sf1ascs', and new GLOBALHOST 'sf1global'. Both SAP ASCS instance and SOFS file share are running on the SAME cluster. 
SAP ASCS instance is configured to access SAP GLOBALHOST using local path e.g. C:\usr\sap\SF1\SYS\...
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory=$True,HelpMessage="Path to ASCS or SCS Instance Profile")]
    [string]$PathToAscsScsInstanceProfile,

    [Parameter(Mandatory=$True,HelpMessage="New ASCS or SCS instance host name")]
    [string]$NewASCSHostName,

    [Parameter(Mandatory=$True,HelpMessage="New SAP GLOBAL host name")]
    [string]$NewSAPGlobalHostName
)

BEGIN  {
    # Check if ASCS / SCS profile file exists
    if (-not (Test-Path $PathToAscsScsInstanceProfile)){
        Write-Error "Profile $PathToAscsScsInstanceProfile not found!"
        break
    }

     #Get ASC / SCS profile file name & path
    $AscsScsFileName = (Get-ChildItem -Path $PathToAscsScsInstanceProfile).Name
    $SAPProfileDrectory = (Get-ChildItem -Path $PathToAscsScsInstanceProfile).DirectoryName

    # Check if DEFAULT.PFL profile file exists
    [string] $PathToDEFAULTProfile = $SAPProfileDrectory + "\DEFAULT.PFL"
    if (-not (Test-Path $PathToDEFAULTProfile)){
        Write-Error "Profile $PathToDEFAULTProfile not found!"
        break
    }
}

PROCESS{


    ####################################
    # Backup (A)SCS and DEFAULT Profile
    ####################################    
    $stamp = Get-Date -F yyyy-MM-dd_HH-mm
    $BackupPath = "$SAPProfileDrectory\BACKUP-$stamp"
    
    Write-Host
    Write-Host "[INFO] Backing up profiles to the $BackupPath folder ..."
    Write-Host
    
    Write-Verbose "Creating backup folder $BackupPath ..."
    New-Item -Path $BackupPath -ItemType Directory

    #Backup (A)SCS profile
    Copy-Item -Path $PathToAscsScsInstanceProfile -Destination $BackupPath
    #Backup DEFAULT profile
    Copy-Item -Path "$SAPProfileDrectory\DEFAULT.PFL" -Destination $BackupPath


    ###################################
    # Update ASCS / SCS Profile
    ###################################    
   
    # Check local or UNC path
    if($SAPProfileDrectory -match  "\\\\\w+"){
        $UNCPathToprofile = $True
    }else{
        $UNCPathToprofile = $false
        $SAPDisk = $SAPProfileDrectory.Substring(0,2)
        $UsrSAPFolder = $SAPProfileDrectory.Substring(0,10)
    }

    #Check if it is ASCS or SCS profile
    if([regex]::Match($AscsScsFileName, "^\w{3}_SCS\d{2}_").Success){
        # SCS Instance
        $IsSCSInstance = $True
        $IsASCSInstance = $false        
    }else{
        # ASCS Instance
        $IsSCSInstance = $false
        $IsASCSInstance = $True        
    }

    if($IsSCSInstance -eq $True){
        if($UNCPathToprofile -eq $True){
            Write-Host
            Write-Host "[INFO] Configuring SAP SCS instance to use UNC path $SAPProfileDrectory"
        }
        else{
            Write-Host "[INFO] Configuring SAP SCS instance to use local path $SAPProfileDrectory"
        }
    }else{
        if($UNCPathToprofile -eq $True){
            Write-Host
            Write-Host "[INFO] Configuring SAP ASCS instance to use UNC path $SAPProfileDrectory"
        }
        else{
            Write-Host
            Write-Host "[INFO] Configuring SAP ASCS instance to use local path $SAPProfileDrectory"
        }
    }

    # Get old ASCS / SCS host name from profile name
    $Value = [regex]::Match($AscsScsFileName, "^\w{3}_\w{0,1}SCS\d{2}_").Value
    $OldSCSHostName = $AscsScsFileName.Substring($Value.Length)

    $NewAscsSCSInstanceNameProfile = $Value + $NewASCSHostName
    $NewPathToAscsScsInstanceProfile = $SAPProfileDrectory + "\" + $NewAscsSCSInstanceNameProfile
    $content = Get-Content -Path $PathToAscsScsInstanceProfile

    $FoundSAPLOCALHOSTParameter          = $false
    $FoundGwNetStatOnceParameter         = $false
    $FoundEnqueKeepaliveParameter        = $false
    $FoundSAPGLOBALHOSTPATHParameter     = $false
    $FoundSAPServiceHACheckNodeParameter = $false

    Write-Host
    Write-Host "[INFO] Updating parameters of the $PathToAscsScsInstanceProfile profile ..."
    Write-Host

    ForEach ($line in $content){
        Write-Verbose ""
        if($line -match  "^#"){
            Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
            Write-Verbose "Not changing line:"
            Write-Verbose $line
    
        }elseif($line -match "^SAPGLOBALHOST"){
            if($line -match $OldSCSHostName){
                $line = $line -replace $OldSCSHostName, $NewSAPGlobalHostName
                Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
                Write-Verbose "Updated profile parameter:"
                Write-Verbose $line
                #$line -split "=",2                        
            }
        }elseif($line -match "^DIR_PROFILE"){
            if(-not $UNCPathToprofile){
                #use local path to profile
                $line = "_DIR_PROFILE = $SAPProfileDrectory"
                Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
                Write-Verbose "Updated profile parameter:"
                Write-Verbose $line
            }elseif ($UNCPathToprofile -and ($line -match $OldSCSHostName)){
                #use UNC path to profile
                $line = $line -replace $OldSCSHostName, $NewSAPGlobalHostName
                Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
                Write-Verbose "Updated profile parameter:"  
                Write-Verbose $line                  
            }

        }elseif($line -match "^_PF"){
            if($line -match $OldSCSHostName){
                $line = $line -replace $OldSCSHostName, $NewASCSHostName            
                Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
                Write-Verbose "Updated profile parameter:"
                Write-Verbose $line
            }

        }elseif($line -match "^_SAPLOCALHOST"){
            if($line -match $OldSCSHostName){
                $FoundSAPLOCALHOSTParameter = $True
                $line = $line -replace $OldSCSHostName, $NewASCSHostName            
                Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
                Write-Verbose "Updated profile parameter:"
                Write-Verbose $line      
            }

         }elseif($line -match "^_gw/netstat_once"){
            $FoundGwNetStatOnceParameter = $True            
            $line = "gw/netstat_once = 0"    
            Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
            Write-Verbose "Updated profile parameter:"
            Write-Verbose $line                            

         }elseif($line -match "^_enque/encni/set_so_keepalive"){
            $FoundEnqueKeepaliveParameter = $True
            $line = "enque/encni/set_so_keepalive = true"       
            Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
            Write-Verbose "Updated profile parameter:"
            Write-Verbose $line      
       
        }elseif($line -match "^service/ha_check_node"){
            $FoundSAPServiceHACheckNodeParameter = $True
            $line = "service/ha_check_node = 1"       
            Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
            Write-Verbose "Updated profile parameter:"
            Write-Verbose $line      
       

        }elseif($line -match "^GLOBALHOSTPATH"){
            $FoundSAPGLOBALHOSTPATHParameter = $True
            $line = "GLOBALHOSTPATH = $UsrSAPFolder"            
            Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
            Write-Verbose "Updated profile parameter:"
            Write-Verbose $line           
    
        }elseif($line -match "^Restart_Program"){
            $line = $line -replace "^Restart_Program", "Start_Program"            
            Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
            Write-Verbose "Updated profile parameter:"
            Write-Verbose $line
        }else{
            Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
            Write-Verbose "Not changing parameter:"
            Write-Verbose $line
        }
    }

    if(-not $FoundSAPLOCALHOSTParameter){
        # Added SAPLOCALHOST parameter
        $line = "SAPLOCALHOST = $NewASCSHostName"
        Add-Content -Value "# Added SAPLOCALHOST parameter" -Path $NewPathToAscsScsInstanceProfile
        Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
        Write-Verbose ""
        Write-Verbose "Added new profile parameter:"
        Write-Verbose $line
    }

    if(-not $FoundGwNetStatOnceParameter){
        # Added gw/netstat_once parameter
        $line = "gw/netstat_once = 0"
        Add-Content -Value "# Added gw/netstat_once parameter" -Path $NewPathToAscsScsInstanceProfile
        Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
        Write-Verbose ""
        Write-Verbose "Added new profile parameter:"
        Write-Verbose $line
    }

    if(-not $FoundEnqueKeepaliveParameter){
        # Added enque/encni/set_so_keepalive parameter
        $line = "enque/encni/set_so_keepalive = true"
        Add-Content -Value "# Added enque/encni/set_so_keepalive parameter" -Path $NewPathToAscsScsInstanceProfile
        Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
        Write-Verbose ""
        Write-Verbose "Added new profile parameter:"
        Write-Verbose $line
    }

    if(-not $FoundSAPServiceHACheckNodeParameter ){
        # Added enque/encni/set_so_keepalive parameter
        $line = "service/ha_check_node = 1"
        Add-Content -Value "# Added service/ha_check_node parameter" -Path $NewPathToAscsScsInstanceProfile
        Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
        Write-Verbose ""
        Write-Verbose "Added new profile parameter:"
        Write-Verbose $line
    }

    if((-not $FoundSAPGLOBALHOSTPATHParameter) -and (-not $UNCPathToprofile)) {
        # Added enque/encni/set_so_keepalive parameter
        $line = "GLOBALHOSTPATH = $UsrSAPFolder"
        Add-Content -Value "# Added GLOBALHOSTPATH parameter" -Path $NewPathToAscsScsInstanceProfile
        Add-Content -Value $line -Path $NewPathToAscsScsInstanceProfile
        Write-Verbose ""
        Write-Verbose "Added new profile parameter:"
        Write-Verbose $line
    }

    
    Write-Host
    Remove-Item -Path $PathToAscsScsInstanceProfile
    Write-Host "[INFO] New profile is '$NewPathToAscsScsInstanceProfile'."
    Write-Host
    Write-Host "[INFO] Update of SAP ASCS/SCS $NewPathToAscsScsInstanceProfile profile done!"
 

    ###############################
    # Update DEFAULT.PFL profile
    ###############################
    Update-SAPDEFAULTProfile -PathToDEFAULTProfile $PathToDEFAULTProfile -NewASCSHostName $NewASCSHostName -NewSAPGlobalHostName $NewSAPGlobalHostName
   
    }
    
    END {
        Write-Host
        Write-Host "[INFO] Update finished!"
        Write-Host    
    }
}



function Update-SAPDEFAULTProfile{

<#
.SYNOPSIS 
Update-SAPDEFAULTProfile updates SAP DEFAULT.PFL profile file to new ASCS/SCS hostname and new GLOBALHOST name. 

.DESCRIPTION
Update-SAPDEFAULTProfile updates SAP DEFAULT.PFL profile file to new ASCS/SCS hostname and new GLOBALHOST name. 

You can specify path to original DEFAULT.PFL profile file using local or UNC path. 


.PARAMETER PathToDEFAULTProfile 
The local or UNC path to SAP DEFAULT.PFL profile file. 

.PARAMETER NewASCSHostName 
New SAP ASCS / SCS host name (Message and Enqueue Server host name). 

.PARAMETER NewSAPGlobalHostName 
New SAP GLOBALHOST host name. 

.EXAMPLE 
Update-SAPDEFAULTProfile -PathToDEFAULTProfile \\ja1global\sapmnt\JA1\SYS\profile\DEFAULT.PFL -NewASCSHostName ja1scs -NewSAPGlobalHostName ja1global

Update SAP DEFAULT.PFL profile to new  ASCS / SCS host 'ja1scs', and new GLOBALHOST 'ja1global'. SOFS is reached using 'ja1global' hostname. 

.EXAMPLE 
Update-SAPDEFAULTProfile -PathToDEFAULTProfile C:\usr\sap\SF1\SYS\profile\DEFAULT.PFL -NewASCSHostName sf1ascs -NewSAPGlobalHostName sf1global -Verbose

Update SAP  DEFAULT.PFL profile to new ASCS / SCS  host 'sf1ascs', and new GLOBALHOST 'sf1global'. -Verbose will print more information.
#> 

[CmdletBinding()]
param(
    [Parameter(Mandatory=$True,HelpMessage="Path to DEFAULT.PFL profile file")]
    [string]$PathToDEFAULTProfile,

    [Parameter(Mandatory=$True,HelpMessage="New ASCS or SCS instance host name")]
    [string]$NewASCSHostName,

    [Parameter(Mandatory=$True,HelpMessage="New SAP GLOBAL Host name")]
    [string]$NewSAPGlobalHostName
)

BEGIN  {
    # Check if DEFAULT.PFL profile file exists
    if (-not (Test-Path $PathToDEFAULTProfile)){
        Write-Error "Profile $PathToDEFAULTProfile not found!"
        break
    }
}

PROCESS{

    $SAPProfileDrectory = (Get-ChildItem -Path $PathToDEFAULTProfile).DirectoryName
    $PathToTempDEFAULTProfile = $SAPProfileDrectory + "\DEFAULT-TMP.PFL"
    $content = Get-Content -Path $PathToDEFAULTProfile    

    Write-Host
    Write-Host "[INFO] Updating parameters of the $PathToDEFAULTProfile profile ..."
    Write-Host


    ForEach ($line in $content){
        Write-Verbose ""
        if($line -match  "^#"){
            Add-Content -Value $line -Path $PathToTempDEFAULTProfile
            Write-Verbose "[INFO] Not changing line:"
            Write-Verbose $line
    
        }elseif($line -match "^SAPGLOBALHOST"){
            $line = "SAPGLOBALHOST = $NewSAPGlobalHostName"
            Add-Content -Value $line -Path $PathToTempDEFAULTProfile
            Write-Verbose "[INFO] Updated profile parameter:"
            Write-Verbose $line            

        }elseif($line -match "^rdisp/mshost"){
            $line = "rdisp/mshost =  $NewASCSHostName"
            Add-Content -Value $line -Path $PathToTempDEFAULTProfile 
            Write-Verbose "[INFO] Updated profile parameter:"
            Write-Verbose $line                                  

         }elseif($line -match "^enque/serverhost"){
            $line = "enque/serverhost = $NewASCSHostName"
            Add-Content -Value $line -Path $PathToTempDEFAULTProfile
            Write-Verbose "[INFO] Updated profile parameter:"
            Write-Verbose $line    
            

          }elseif($line -match "^j2ee/scs/host"){
            $line = "j2ee/scs/host = $NewASCSHostName"
            Add-Content -Value $line -Path $PathToTempDEFAULTProfile
            Write-Verbose "[INFO] Updated profile parameter:"
            Write-Verbose $line              
         
        }else{
            Add-Content -Value $line -Path $PathToTempDEFAULTProfile
            Write-Verbose "[INFO] Not changing profile parameter:"
            Write-Verbose $line          
        }
    }

    Write-Host    
    Remove-Item -Path $PathToDEFAULTProfile    
    Rename-Item -Path $PathToTempDEFAULTProfile -NewName "$PathToDEFAULTProfile"
 
 }

 END {
    Write-Host
    Write-Host "[INFO] Update of $PathToDEFAULTProfile profile done!"
 }
}
