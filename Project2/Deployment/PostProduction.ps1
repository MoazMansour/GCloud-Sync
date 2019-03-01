###############################################################################
# NAME:      trulia-WF-V10.ps1
# AUTHOR:    Moaz Mansour
# E-MAIL:	   moaz.mansour@gmail.com
# DATE:      01/31/2019
# LANG:      PowerShell
#
# This script manages the Trulia Project Post-Production WorkFlow.
#
# VERSION HISTORY:
# 1.0    01/31/2019    Initial Version
###############################################################################

#####################################################
############### Trulia PostProduction ###############
#####################################################

#Silence Error to display on screen
$ErrorActionPreference= 'silentlycontinue'

################################################################################################
#### Read Config File ####
$current_loc = Get-Location
$config_file = "$($current_loc)\config.txt"
$change_script = "$($current_loc)\ChangeConfig.ps1"

function read_config {
  Set-Variable -Name "content" -Value (Get-Content -Path $config_file) -Scope Global
  Set-Variable -Name "replacment" -Value (Get-Content -Path $config_file -RAW) -Scope Global
  ForEach ($line in $content){
     $var = $line.Split(';')
     if (-Not (Test-Path "Variable:\$($var[0])")){
       New-Variable -Name $var[0] -Value $var[1] -Scope Global
     } Else {
       Set-Variable -Name $var[0] -Value $var[1] -Scope Global
     }
  }
}

#Read variables from config file
read_config

#Global Variables
$client = "Trulia"
$client_path = "$($dam_path)\$($client)"

##Global Variables
$current_date = Get-Date -UFormat "%Y%m%d"
$csv_file = "shoot_export_$($current_date).csv"
$csv_path = "$($csv_loc)\$($csv_file)"

$massupdater_file = "VendorUpdate_$($current_date).csv"
$massupdater = "$($massupdater)\$($massupdater_file)"

#initate a list for photosets
$ImportedID = @{}
$NAS_ids = @{}
$project_shoots = @{}
$SetID = @()
$list_out = @()

$error_count = 0
$progress = 0

#Status Bar
$stat = ("Reading CSV File", "Reading Listings on local Server", "Comparing CS Export to local Server", "Pick up your shoots", "Copy Selections to local machine", "Copying Master Catalog", "Done")

################################################################################################
#### Print out Progress ####
function show-progress {
    param([int]$n, [int]$x, [string]$end)
    $percentage = [math]::Truncate(($n+1)/$stat.count*100)
    Write-Progress -Id 1 -Activity "Trulia PostProduction" -status "$($stat[$n]) $($percentage)%" -PercentComplete $percentage
    if (-Not ($n -eq 0)) {
        if($x -ne $Error.Count) {
            Write-Host "[Error] : " -ForegroundColor Red -NoNewline
            Write-Host "$($stat[($n-1)])"
            While ($x -lt $Error.Count){
                $msg = $Error[$x].Exception.Message
                Write-Host "  Error message: $($msg)" -ForegroundColor Red
                $x += 1
            }
        } Else {
            if (-Not $end) {
                Write-Host "[Done] : " -ForegroundColor Green -NoNewline
                Write-Host "$($stat[($n-1)])"
            }
        }
    return $x
    }
}

################################################################################################
#### Copying Progress ####
function copy-progress {
    param([string]$from, [string]$to, [string]$call, [string]$shoot)
    $from_count = Get-ChildItem -Path "$($from)" -Recurse| Measure-Object | %{$_.Count}
    $to_count = Get-ChildItem -Path "$($to)" -Recurse| Measure-Object | %{$_.Count}
    if ( $call -eq "copy") {
        $report = "Copying ($($shoot))"
        Start-Job -Name "Copy Items" -ScriptBlock {
            param($source,$dest)
            Copy-Item $source $dest -Recurse -Force
        } -ArgumentList $from, $to | Out-Null
    } Else {
        $report = "Moving ($($shoot))"
        Start-Job -Name "Moving Items" -ScriptBlock {
            param($source, $dest)
            Move-Item -Path $source -Destination $dest -Force
        } -ArgumentList $from, $to | Out-Null
    }

    While (($to_count -le $from_count) -and ($from_count -ne 0)) {
        $percentage = [math]::Truncate($to_count/$from_count*100)
        Write-Progress -Id 2 -ParentId 1 -Activity "$($report)" -status "$($percentage)%" -PercentComplete $percentage
        $to_count = Get-ChildItem -Path "$($to)" -Recurse| Measure-Object | %{$_.Count}
        $to_count += 1
    }
}

################################################################################################
#### Extract Set ID number from Listing Name ####
function extract-id {
    param( [string]$nbrhood_name)
    $pattern = '\d\d\d+'
    $check = $nbrhood_name -match $pattern
    $nbrhood_id = $matches[0]
    return $nbrhood_id
}

################################################################################################
#### Download CSV Export File ####
function Download-CSV {
    Write-Host "Downloading CS CSV File"
    ## Delete previous exports to avoid overlapping
    Remove-Item -Path "$($csv_loc)\shoot_export_*" -Force
    ##
    ##Call the python Script
    $chrome_driver = "$($current_loc)\chromedriver.exe"
    $downloader = "$($current_loc)\Downloader.py"
    python $downloader $username $password $chrome_driver $export_link $csv_path

    $download_status = Test-Path $csv_path -PathType Leaf
    if ($download_status) {
        Write-Host "[Done] : " -ForegroundColor Green -NoNewline
        Write-Host "CSV File Downloaded"
    } Else {
        Write-Host "Error: Please check internet connection and retry" -ForegroundColor Red
        $flag = 8
        While ($flag -eq 8){
          $in = Read-Host "Retry [Y/N]?"
          if (($in -eq "Y") -or ($in -eq "y")){
            $flag = 0
            Write-Host "`r"
            Download-CSV
          } ElseIf (($in -eq "N") -or ($in -eq "n")){
            $flag = 0
            Write-Host "`r"
            Write-Host "Good Bye!" -ForegroundColor Yellow
            Exit
          } Else {
            Write-Host "`r"
            Write-Host "Error: Please type in Y or N only" -ForegroundColor Red
          }
    }
  }
}

################################################################################################
#### Read shoots on Local Server ####
function read_nbrhoods($shoot){
  $nbr_ids = @()
  $path = "$($client_path)/$($project)/$($shoot)/Photo"
  $nbrhoods = Get-ChildItem -Directory $path
  ForEach ($nbrhood in $nbrhoods) {
    $id = extract-id $nbrhood
    $nbr_ids += $id
  }
  return $nbr_ids
}

################################################################################################
#### Read shoots on Local Server ####
function read_shoots($project){
  $nbr_ids = @()
  $shoot_names = @()
  $shoots = Get-ChildItem -Directory "$($client_path)/$($project)"
  ForEach ($shoot in $shoots) {
    $nbr_ids = read_nbrhoods $shoot
    $shoot_names += $shoot
    $Global:NAS_ids.add($shoot,$nbr_ids)
  }
  return $shoot_names
}

################################################################################################
#### Read Sets on Local Server ####
function read_NAS {
  $shoot_names = @()
  $projects = Get-ChildItem -Directory $client_path
  ForEach ($project in $projects) {
    if ($project -match "Trulia - Neighborhoods - Phoenix az") {
        $shoot_names = read_shoots $project
        if ($project -in $project_shoots.Keys){
        $Global:project_shoots.set($project,$shoot_names)
        } Else {
        $Global:project_shoots.add($project,$shoot_names)
        }
    }
  }
}

################################################################################################
#### Read Sets on Local Server ####
function check_input{
  param([string]$in, [int]$count)
  $in_list = @()
  $in_list = $in.split(',')
  ForEach ($item in $in_list){
    $n = [int]$item
    if (($n -lt $count) -and ($n -ge 0)) {
      continue
    } Else {
      return "FALSE"
    }
  }
  return "TRUE"
 }

################################################################################################
#### UI for Shoots Picking ####
function select_shoots {
  Write-Host "`r"
  Write-Host "########################################################" -ForegroundColor DarkGreen
  Write-Host "################ Trulia Shoots List ####################"
  Write-Host "########################################################" -ForegroundColor DarkGreen
  Write-Host "`r `n `r"

  Write-Host "Hi, " -NoNewline
  Write-Host $username -ForegroundColor Magenta
  Write-Host "`r"
  Write-Host "Welcome to Trulia Post-Production tool designed by Blink Tech team"
  Write-Host "`r"
  Write-Host "Today, the total number of shoots ingested is " -NoNewline
  Write-Host "$($list_out.count)." -ForegroundColor Yellow
  Write-Host "Please make your selections from the list below in a comma separated format (eg: 0,1,2)"
  Write-Host "`r"
  $i = 0
  While($i -lt $list_out.count){
    Write-Host "[$($i)] : " -ForegroundColor Green -NoNewline
    $key = $list_out[$i].Name
    $out_Ids = $ImportedID[$key] -join "-"
    $output = '{0,-39} : ({1,5})' -f $key, $out_Ids
    Write-Host "$($output)"
    $i += 1
  }
  Write-Host "`r"
  $flag = 8
  While ($flag -eq 8){
    Write-Host "Your selections are " -ForegroundColor Green -NoNewline
    $in = Read-Host "(e.g. 0,1,2)"
    if (($in -match '[\d,]+')) {
      $check = check_input $in $list_out.Count
      if ($check -eq "TRUE") {
        $flag = 0
        Write-Host "`r"
        Write-Host "Ok, Roger that!" -ForegroundColor Yellow
        Write-Host "`r"
        return $in
      } Else {
        Write-Host "`r"
        Write-Host "Oops, your input is out of range. Please stick to the list" -ForegroundColor Red
        Write-Host "`r"
      }
    } Else {
      Write-Host "`r"
      Write-Host "Oops, I only take this format (eg 0,1,2)" -ForegroundColor Red
      Write-Host "`r"
    }
  }
}

################################################################################################
#### Find shoot project ####
function find_project($shoot) {
  ForEach ($project in $project_shoots.Keys) {
    if ($shoot -in $project_shoots[$project]){
      return $project
    }
  }
}

################################################################################################
#### Copy shoots from Server to local machine  ####
function shoots_copy() {
  param([string]$target, [string]$local_dest)
  $tagret_list = @()
  $target_list = $target.Split(',')
  Foreach ($item in $target_list) {
    $shoot = $list_out[[int]$item]
    $project = find_project $shoot
    $source = "$($dam_path)\$($client)\$($project)\$($shoot)\*"
    $final_dest = "$($local_dest)\$($shoot)\"
    if (-Not (Test-Path $final_dest -PathType Container)) {
      New-Item -ItemType directory -Path $final_dest | Out-Null
    }
    copy-progress $source $final_dest "copy" $shoot
  }
}

################################################################################################
#### Copy master catalog and rename to NBRHood  ####
function copy_catalog {
  param([string]$to, [string]$nbrhood)
  $catalog = Get-ChildItem -File $master_path -Filter "*.lrcat"
  $source = "$($master_path)\$($catalog)"
  $dest = "$($to)\$($nbrhood).lrcat"
  copy-progress $source $dest "copy" "$($nbrhood).lrcat"
  }

################################################################################################
#### Copy Lightroom settings to NBRhood  ####
function copy_settings {
  param([string]$to, [string]$nbrhood)
  $source = "$($master_path)\Lightroom Settings"
  $dest = $to
  copy-progress $source $dest "copy" "$($nbrhood) Settings"
  }

################################################################################################
#### Copy shoots from Server to local machine  ####
function master_catalog() {
  param([string]$local_dest)
  $shoots = Get-ChildItem -Directory "$($local_dest)"
  ForEach ($shoot in $shoots) {
    $nbrhoods = Get-ChildItem -Directory "$($local_dest)\$($shoot)\Photo"
    ForEach ($nbrhood in $nbrhoods) {
      $to = "$($local_dest)\$($shoot)\Photo\$($nbrhood)\Catalog"
      $add_assets = "$($local_dest)\$($shoot)\Photo\$($nbrhood)\Additional Assets"
      if (-Not (Test-Path $to -PathType Container)) {
           New-Item -ItemType directory -Path $to | Out-Null
           New-Item -ItemType Directory -Path $add_assets | Out-Null
      }
      $catalog_check = Get-ChildItem -File $to -Filter "*.lrcat" -Recurse | Measure-Object | %{$_.Count}
      if($catalog_check -ge 1){
        continue
      } Else {
        copy_catalog $to $nbrhood
        copy_settings $to $nbrhood
      }
    }
  }
}

################################################################################################
#### End of Script Message ####
function end_script() {
  ##Pop-up window to confirm process complete
  Write-Host "`r"
  Write-Host "Awesome, You are off to go!" -ForegroundColor Yellow
  $wshell = New-Object -ComObject Wscript.Shell
  $wshell.Popup("Trulia PostProduction Script Completed",0,"Done",0x1)
  Exit
}

################################################################################################
#### Main Body ###
##Clear space for progress bar
"`r `n `r `n `r `n `r `n `r `n `r `n `n `n `n `n `n"

#Check if config need to be changed
if ($change_flag -eq "TRUE") {
  &$change_script
  read_config
  }

#Download the CSV file
Download-CSV

##Clear Error Log before start
$Error.clear()

##Stage 1: Reading CSV -> Update Progress
$error_count = show-progress $progress $error_count

##Read Set Ids from the CSV file
Import-Csv $csv_path |
    ForEach-Object {
      $status = $_."Timeline"
      $pattern = 'Assets\sdelivery\s+.\sIn\sprogress.+\s+.\sCompleted'
      $seq_patt = 'Sequencing[a-zA-z\s-\d\/\,\:\(\)]+\sCompleted'
      $retouch_patt = 'Image retouch[a-zA-z\s-\d\/\,\:\(\)]+\sCompleted'
      if (-Not ($status -match $pattern) -and -Not ($status -match $retouch_patt) -and ($status -match $seq_patt)) {
        $ShootName = $_."Name"
        $ShootName = [string]$ShootName
        $ext_id = $_."External ID"
        $SetID = $ext_id.split("/")
        $Global:ImportedID.add($ShootName,$SetID)
      }
    }

##Stage 2: Reading from Local Server -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Read existing sets on NAS
read_NAS

##Stage 3: Comparing CS Export to NAS shoots -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Compare shoot names from CS to NAS
Foreach ($id in $NAS_ids.Keys) {
    if ($id -in $ImportedID.Keys) {
        $list_out += $id
    }
}

##Stage 4: Populate the list On Screen -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

if ($list_out.Count -gt 0) {
    $in = select_shoots
} Else {
    Write-Host "`r"
    Write-Host "Wow, all the shoots are marked as complete. I think you might enjoy the rest of your day!" -ForegroundColor Magenta
    $progress = $stat.Count-1
    $error_count = show-progress $progress $error_count "End"
    end_script
}

##Stage 5: Copy selections to local machine -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

$dest_name = Get-Date -UFormat "%m-%d-%Y"
$dest = "$($local_path)\$($dest_name)"
if (-Not (Test-Path $dest -PathType Container)) {
  New-Item -ItemType directory -Path $dest | Out-Null
}

shoots_copy $in $dest

##Stage 6: Copy Master Catalog to local folder -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

master_catalog $dest

##Stage 7: Done -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count
end_script
