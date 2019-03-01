###############################################################################
# NAME:      VendorShip-V10.ps1
# AUTHOR:    Moaz Mansour
# E-MAIL:	   moaz.mansour@gmail.com
# DATE:      01/23/2019
# LANG:      PowerShell
#
# This script manages the Airbnb Project Client Delivery.
#
# VERSION HISTORY:
# 1.0    01/23/2019    Initial Version
###############################################################################

#####################################################
################## Vendor Shippment #################
#####################################################

#Silence Error to display on screen
$ErrorActionPreference= 'silentlycontinue'

# ## Reading variables from config file
 $current_loc = Get-Location
 $content = Get-Content -Path "$($current_loc)\config.txt"
 ForEach ($line in $content){
   $var = $line.Split(';')
   if (-Not (Test-Path "Variable:\$($var[0])")){
     New-Variable -Name $var[0] -Value $var[1] -Scope Global
   } Else {
     Set-Variable -Name $var[0] -Value $var[1] -Scope Global
   }
}

##Directories path parameters
$current_date = Get-Date -UFormat "%Y%m%d"
$csv_file = "photo_sets_export_$($current_date).csv"
$csv_path = "$($csv_loc)\$($csv_file)"

$massupdater_file = "VendorUpdate_$($current_date).csv"
$massupdater = "$($massupdater)\$($massupdater_file)"

##Where to put the log files
$del_log = "$($log_dir)\vendor_shippment_log.txt"
##############################

#initate a list for photosets
$SetID = @()
$listings = @()
$listings_list = @()
$tracker_err_list = @()
$update_list = @()
$old_csv = @()
$listing_count = @{}
$vendor_paths = @{}
$vendor_default = [ordered]@{}
$vendor_names = @{}
$vendor_init_default = @{}
$vendor_assignments = @{}
$ordered_listings = [ordered]@{}
$list_teams = [ordered]@{}
#count number of errors for reporting
$tracker_err = 0
$progress = 0
$error_count = 0
##############################

#Status Bar
$stat = ("Reading CSV File", "Copying Selects to Local Folder", "Comparing CS Export to Ready for Client", "Shipping to Vendors", "Writing to log files", "Changing Status on CS", "Archiving Shipped", "Done")

################################################################################################
#### Read Vendor Variables from Config ####
function read_vendor {
  Set-Variable -Name "list_team_names" -Value $team_names.Split(',') -Scope Global
  Set-Variable -Name "list_team_paths" -Value $team_paths.Split(',') -Scope Global
  Set-Variable -Name "list_team_numbers" -Value $team_numbers.Split(',') -Scope Global
  Set-Variable -Name "list_team_default" -Value $team_default.Split(',') -Scope Global
  $i = 0
  while ($i -lt $list_team_numbers.count){
    $Global:vendor_names.add($list_team_numbers[$i],$list_team_names[$i])
    $Global:vendor_paths.add($list_team_numbers[$i],$list_team_paths[$i])
    $Global:vendor_init_default.add($list_team_numbers[$i],[int]$list_team_default[$i])
    $i += 1
  }
  $x = $vendor_init_default.GetEnumerator() | Sort-Object -Property Value
  ForEach ($item in $x) {
    $Global:vendor_default.add($item.key,$item.value)
  }
}


################################################################################################
#### Extract Set ID number from Listing Name ####
function orig_id {
  param([string]$id)
  $pattern = '\d\d\d+'
  $check = $id -match $pattern
  $key = [string]$matches[0]
  return $key
  }
################################################################################################
#### Extract Set ID number from Listing Name ####
function extract-id {
    param( [string]$home_listing)
    $pattern = '(\d\d\d+)'
    $check = $home_listing -match $pattern
    $listing_id = $matches[0]
    return $listing_id
}

################################################################################################
#### Print out Progress ####
function show-progress {
    param([int]$n, [int]$x)
    $percentage = [math]::Truncate(($n+1)/$stat.count*100)
    Write-Progress -Id 1 -Activity "Airbnb Ready for Vendor" -status "$($stat[$n]) $($percentage)%" -PercentComplete $percentage
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
            Write-Host "[Done] : " -ForegroundColor Green -NoNewline
            Write-Host "$($stat[($n-1)])"
        }
    return $x
    }
}

################################################################################################
#### Copying Progress ####
function copy-progress {
    param([string]$from, [string]$to, [string]$call)
    $from_count = Get-ChildItem -Path "$($from)" -Recurse| Measure-Object | %{$_.Count}
    $to_count = Get-ChildItem -Path "$($to)" -Recurse| Measure-Object | %{$_.Count}
    $id = extract-id $from
    if ( $call -eq "copy") {
        $report = "Copying Listing ($($id))"
    } Else {
        $report = "Moving Listing ($($id))"
    }
    While (($to_count -le $from_count) -and ($from_count -ne 0)) {
        $percentage = [math]::Truncate($to_count/$from_count*100)
        Write-Progress -Id 2 -ParentId 1 -Activity "$($report)" -status "$($percentage)%" -PercentComplete $percentage
        $to_count = Get-ChildItem -Path "$($to)" -Recurse| Measure-Object | %{$_.Count}
        $to_count += 1
    }
}

################################################################################################
#### Copy and rename listings from Ready for Vendor to Selects  ####
function listings-copy {
    ## Empty folder to avoid overlapping
    Remove-Item -Path "$($select_path)\*" -Force | Out-Null
    ##

    $return_list = @()
    Foreach ($listing in $listings) {
        $listing_id = extract-id $listing
        $return_list += $listing_id
        $source = "$($ready_path)\$($listing)\SELECT*\*"
        $dest = "$($select_path)\$($listing)\SELECTS\"
        if (-Not (Test-Path $dest -PathType Container)) {
            New-Item -ItemType directory -Path $dest | Out-Null
        }
        Start-Job -Name "Listing Copying" -ScriptBlock {
            param($source, $dest)
            Copy-Item $source $dest -Recurse -Force
        } -ArgumentList $source, $dest | Out-Null
        copy-progress $source $dest "copy"
    }
    return $return_list
}

################################################################################################
#### Delivered Log File ####
function log-delivery {
    Set-Content -path $del_log -Value ">>>Vendor Shipment Log<<< `r`n"
    Add-Content -path $del_log -Value "_________________________________"
    Add-Content -path $del_log -Value ">Total Delivered: $($listings_list.Count)"
    Add-Content -path $del_log -Value "_________________________________"
    Add-Content -path $del_log -Value "`r"
    Add-Content -path $del_log -Value ">Updated on Tracker: $($update_list.Count)"
    Add-Content -path $del_log -Value "_________________________________"
    Add-Content -path $del_log -Value "`r"
    $output = '{0,-15} : {1,5} : {2}' -f "Set ID", "Count", "Assigned Team"
    Add-Content -path $del_log -Value $output
    ForEach ($id in $update_list) {
      $key = orig_id $id
      $output = '{0,-15} : {1,5} : {2} ({3})' -f $id, $listing_count[$key], $list_teams[$key], $vendor_names[$list_teams[$key]]
      Add-Content -path $del_log -Value $output
    }
    Add-Content -path $del_log -Value "_________________________________"
    Add-Content -path $del_log -Value "`r"
    Add-Content -path $del_log -Value ">Missing on Tracker: $($tracker_err)"
    Add-Content -path $del_log -Value "_________________________________"
    Add-Content -path $del_log -Value "`r"
    $output = '{0,-10} : {1,5} : {2}' -f "Set ID", "Count", "Assigned Team"
    Add-Content -path $del_log -Value $output
    ForEach ($key in $tracker_err_list) {
      $output = '{0,-10} : {1,5} : {2} ({3})' -f $key, $listing_count[$key], $list_teams[$key], $vendor_names[$list_teams[$key]]
      Add-Content -path $del_log -Value $output
    }
    Add-Content -path $del_log -Value "_________________________________"
    Add-Content -path $del_log -Value ">>>>End of file :)"
}

################################################################################################
#### MassUpdater Output File ####
function massupdater_fn {
    ## Delete previous exports to avoid overlapping
    if (Test-Path $massupdater -PathType Leaf) {
      Remove-Item -Path $massupdater -Force | Out-Null
    }
    ##
    if (-Not $update_list) {
        $header = [PSCustomObject] @{external_id = " "; Vendor = " "; status = " "}
        $header | Export-Csv -Path $massupdater -NoTypeInformation
        return
    }
    $key = orig_id $update_list[0]
    $header = [PSCustomObject] @{external_id = $update_list[0]; Vendor = $list_teams[$key]; status = 'Sent to vendor'}
    $header | Export-Csv -Path $massupdater -NoTypeInformation
    $i = 1
    While ( $i -lt $update_list.Count) {
        $key = orig_id $update_list[$i]
        $content = [PSCustomObject] @{external_id = $update_list[$i]; Vendor = $list_teams[$key]; status = 'Sent to vendor'}
        $content | Export-Csv -Path $massupdater -Append -NoTypeInformation
        $i += 1
    }
}

################################################################################################
#### Download CSV Export File ####
function Download-CSV {
    $timeout = 20
    Write-Host "Downloading Ready for Vendor CSV File"
    ## Delete previous exports to avoid overlapping
    Remove-Item -Path "$($csv_loc)\photo_sets_export_*" -Force
    ##
    Start-Process($ready_link) -WindowStyle Hidden
    $download_status = Test-Path $csv_path -PathType Leaf
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $time_flag = ($timer.Elapsed.TotalSeconds -lt $timeout)
    While ((-Not $download_status) -and ($time_flag)) {
        $download_status = Test-Path $csv_path -PathType Leaf
        $time_flag = ($timer.Elapsed.TotalSeconds -lt $timeout)
        }
    $timer.Stop()
    if ($time_flag) {
        Write-Host "[Done] : " -ForegroundColor Green -NoNewline
        Write-Host "CSV File Downloaded"
    } Else {
        Write-Host "Error: Please check internet connection and retry" -ForegroundColor Red
        $flag = 8
        While ($flag -eq 8){
          $in = Read-Host "Retry [Y/N]?"
          if (($in -eq "Y") -or ($in -eq "y")){
            $flag = 0
            "`r"
            Download-CSV
          } ElseIf (($in -eq "N") -or ($in -eq "n")){
            $flag = 0
            "`r"
            Write-Host "Good Bye!" -ForegroundColor Yellow
            Exit
          } Else {
            "`r"
            Write-Host "Error: Please type in Y or N only" -ForegroundColor Red
          }
    }
  }
}

################################################################################################
#### UI for Vendor Shipment Management ####
function assign_vendors {
  Write-Host "########################################################"
  Write-Host "################ Airbnb Vendor Shipping ################"
  Write-Host "########################################################"
  "`r `n `r `n `r"

  Write-Host "Hi,"
  "`r"
  Write-Host "Welcome to the Airbnb Vendor Shipping tool designed by Blink Tech team"
  "`r"
  Write-Host "Today, the total number of sets ready for vendor is " -NoNewline
  Write-Host "$($listings.count)." -ForegroundColor Yellow
  Write-Host "Usually, the distribution looks like that:"
  "`r"
  ForEach ($team in $Global:vendor_default.Keys){
      $output = '{0,-7} ({1,-12}) > {2,5}' -f $team, $vendor_names[$team], $vendor_default[$team]
      Write-Host "$($output) sets"
  }
  "`r"
  $flag = 8
  While ($flag -eq 8){
    Write-Host "Would you like to make any changes to the usual distribution " -ForegroundColor Green -NoNewline
    $in = Read-Host "[Y/N]?"
    if (($in -eq "Y") -or ($in -eq "y")) {
      $flag = 0
      "`r"
      Write-Host "Ok, sure." -ForegroundColor Yellow
      $in_flag = 8
      Do {
        ForEach ($team in $($vendor_default.Keys)) {$vendor_default[$team] = 0}
        "`r"
        ForEach ($team in $($vendor_default.Keys)){
            $sum = 0
            ForEach ($key in $($vendor_default.keys)) {$sum += $vendor_default[$key]}
            $left_sets = $listings.count-$sum
            change_vendor $team $left_sets
        }
        $sum = 0
        ForEach ($key in $($vendor_default.keys)) {$sum += $vendor_default[$key]}
        $left_sets = $listings.count-$sum
        if ($left_sets -ne 0) {
           Write-Host "Oops, your total assignmnets is not matching to the total number of sets. Please retry!" -ForegroundColor Red
        }
      } While ($left_sets -ne 0)
      Write-Host "Now, the distribution looks like that:"
      "`r"
      ForEach ($team in $vendor_default.Keys){
        $output = '{0,-7} ({1,-12}) > {2,5}' -f $team, $vendor_names[$team], $vendor_default[$team]
        Write-Host "$($output) sets"
      }
      "`r"
    } ElseIf (($in -eq "N") -or ($in -eq "n")){
      $flag = 0
      "`r"
      Write-Host "Ok, Roger that!" -ForegroundColor Yellow
      "`r"
    } Else {
      "`r"
      Write-Host "Error: Please type in Y or N" -ForegroundColor Red
    }
  }
}

################################################################################################
#### Change Vendor Distribution ####
function change_vendor {
  param([string]$vendor,[int]$left)
  Write-Host "We have $($left) sets left in ready for vendor"
  $flag = 8
  While ($flag -eq 8){
    Write-Host "How many would you like to assign to " -ForegroundColor Green -NoNewline
    $in = Read-Host "$($vendor) ($($vendor_names[$vendor]))"
    $value = [int]$in
    if (($in -match '\d+')) {
        if (($value -le $left) -and ($value -ge 0) ) {
            $flag = 0
            "`r"
            $vendor_default[$vendor] = $value
            Write-Host "Great!" -ForegroundColor Yellow
            "`r"
        } Else {
            "`r"
            Write-Host "Oops, this is not compatible to what we have left. Please retry!" -ForegroundColor Red
        }
    } Else {
      "`r"
      Write-Host "Oops, this is not a valid number. Please retry!" -ForegroundColor Red
    }
  }
}

################################################################################################
#### Assign Assets to vendors ####
function assign_assets {
  $n = 0
  $i = 0
  ForEach ($team in $vendor_default.Keys) {
    $n += $vendor_default[$team]
    $assignment = @()
    while ($i -lt $n) {
      $assignment += $ordered_listings[$i].Key
      $list_teams.add($ordered_listings[$i].Key,$team)
      $i += 1
    }
    $vendor_assignments.add($team,$assignment)
  }
}

################################################################################################
#### Assign Assets to vendors ####
function copy_assets {
  Foreach ($team in $vendor_assignments.Keys) {
    $new_folder = Get-Date -UFormat "%m-%d-%Y"
    $dest = "$($vendor_paths[$team])\$($new_folder)"
    if (-Not (Test-Path $dest -PathType Container)) {
                New-Item -ItemType directory -Path $dest | Out-Null
            }
    ForEach ($listing in $vendor_assignments[$team]){
      $target = Get-ChildItem -Directory $select_path -Filter "*($($listing))"
      $source = "$($select_path)\$($target)"
      $full_dest = "$($dest)\"
      if (-Not (Test-Path $full_dest -PathType Container)) {
          New-Item -ItemType directory -Path $full_dest | Out-Null
      }
      Start-Job -Name "Vendor Shipping Copying" -ScriptBlock {
          param($source, $full_dest)
          Move-Item -Path $source -Destination $full_dest -Force
      } -ArgumentList $source, $full_dest | Out-Null
      copy-progress $source $full_dest "move"
    }
  }
}

################################################################################################

#### Copy and rename listings from Ready for Client to Upload  ####
function listings-archive {
    Foreach ($listing in $listings){
        $source = "$($ready_path)\$($listing)"
        $dest = "$($vendor_archive_path)\$($archive_name)\"
        Start-Job -Name "Moving Items" -ScriptBlock {
            param($source, $dest)
            Move-Item -Path $source -Destination $dest -Force
        } -ArgumentList $source, $dest | Out-Null
        copy-progress $source $dest "move"
    }
}

################################################################################################
#### Main Body ###

##Clear space for progress bar
"`r `n `r `n `r `n `r `n `r `n `r `n `n `n `n `n `n"

#Count today's number of ready for vendor
read_vendor
$listings = Get-ChildItem -Directory $ready_path -Filter "Home*"
$total = $listings.Count
$i = 0
While ($i -lt $vendor_default.Count) {
    if ($vendor_default[$i] -ge $total) {
        $vendor_default[$i] = $total
        $total = 0
    } Else {
        $total = $total - $vendor_default[$i]
    }
    $i += 1
}

## Vendor Shipment distribution
assign_vendors

##View username
Write-Host "Username: $($username)"

##Download the CSV file
Download-CSV

##Clear Error Log before start
$Error.clear()

##Stage 1: Reading CSV -> Update Progress
$error_count = show-progress $progress $error_count

##Read Set Ids from the CSV file
Import-Csv $csv_path |`
    ForEach-Object {
        $SetID += $_."Photo set ID"
    }

##Stage 2: Copying SELECTS -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Copy selects from ready for vendor to local machine
$listings_list = listings-copy

##Stage 3: Comparing CS Export to Ready for Vendor -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Check that all folder ids exist in the SetIds exported from CS
Foreach ($id in $listings_list) {
    if (-Not ($SetID -like "$id*")) {
        $tracker_err_list += $id
        $tracker_err += 1
    }
}

##Count and list all Sets to be shipped
$folders = Get-ChildItem -Directory $select_path -filter "Home*"

ForEach ($folder in $folders) {
    $assets_count = Get-ChildItem -File "$($select_path)\$($folder)\SELECTS\*" | Measure-Object | %{$_.Count}
    $id = extract-id $folder
    $listing_count.Add($id, $assets_count)
  }

$ordered_listings = $listing_count.GetEnumerator() | Sort-Object -Property Value

##Stage 4: Vendor Shipping -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Assign ordered assets to vendors and copy them to their destination
assign_assets
copy_assets

##Stage 5: Write Log files -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Create the update list to contain "- RAW" or "- JPEG"
Foreach ($id in $listings_list) {
    if($SetID -like "$id*") {
        $update_item = $SetID -like "$id*"
        $update_list += $update_item
    }
}

##Write log files
log-delivery
massupdater_fn

##Stage 6: Update CS -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Call the python Script
$chrome_driver = "$($current_loc)\chromedriver.exe"
$mass_uploader = "$($current_loc)\MassUploader.py"
python $mass_uploader $massupdater $username $password $chrome_driver $cs_upload

##Stage 7: Archiving -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Create Archive Folder
$archive_name = Get-Date -UFormat "%m-%d-%Y"
if (-Not (Test-Path "$($vendor_archive_path)\$($archive_name)" -PathType Container)) {
            New-Item -ItemType directory -Path "$($vendor_archive_path)\$($archive_name)" | Out-Null
        }

##Archive sets
listings-archive

##Stage 8: End Process -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Pop-up window to confirm process complete
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Airbnb Vendor Shippment Completed",0,"Done",0x1)

########################################### Vendor Shipping Script End ###########################################
