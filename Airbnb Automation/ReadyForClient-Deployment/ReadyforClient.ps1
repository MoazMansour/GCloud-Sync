###############################################################################
# NAME:      ReadyforClient-V12.ps1
# AUTHOR:    Moaz Mansour, Blink
# E-MAIL:    moaz.mansour@blink.la
# DATE:      12/21/2018
# LANG:      PowerShell
#
# This script manages the Airbnb Project Client Delivery.
#
# VERSION HISTORY:
# 1.0    12/14/2018    Initial Version
# 1.1    12/19/2018    Include Archiving
# 1.2    12/21/2018    Includes MassUpdater
# 1.3    01/02/2019    CSV Auto Download/Throw Errors
# 1.4    01/09/2019    MassUpdater Uploader added
# 1.5    01/10/2019    Reading Variables from a Config file
###############################################################################

#####################################################
################## Client Delivery ##################
#####################################################

## Reading variables from config file
$current_loc = Get-Location
$content = Get-Content -Path "$($current_loc)\config.txt"
ForEach ($line in $content){
   $var = $line.Split('$')
   New-Variable -Name $var[0] -Value $var[1]
}

##Directories path parameters
$csv_date = Get-Date -UFormat "%Y%m%d"
$csv_file = "photo_sets_export_$($csv_date).csv"
Write-Host $csv_file
Write-Host $csv_path
$csv_path = "$($csv_path)\$($csv_file)"

$missing_covers = "$($upload_path)\Missing Covers"
$massupdater_file = "MassUpdater_$($csv_date).csv"
$massupdater = "$($massupdater)\$($massupdater_file)"

#$client_path = "Z:\Auto test"
#$upload_path = "Y:\Client\Airbnb\Plus\00 - DARYL Pull\Auto Test"
#$archive_path = "Y:\Client\Airbnb\Plus\Delivered Test"
#$mass_uploader = "C:\Users\Blink Workstation\Desktop\automation\Airbnb Automation\MassUploader-V10.py"

#Export Link
#$export_link = "https://cs.blink.la/photosets/26/63/export.csv?media_type=&market=&vendor_id=&general_status=&status=&status%5B%5D=90000&client_approval=&vendor_status=&reshoot_reason=&qc_assigned_to=&editorial_assigned_to=&crop_cover_assigned_to=&feedback_assigned_to=&technical_assigned_to=&sent_to_client_from=&sent_to_client_to=&feedback_date_from=&feedback_date_to=&sequencing_completed_from=&sequencing_completed_to=&received_from_client_from=&received_from_client_to=&received_from_vendor_from=&received_from_vendor_to=&sent_to_vendor_from=&sent_to_vendor_to=&feedback_completed_r1_from=&feedback_completed_r1_to=&feedback_completed_r2_from=&feedback_completed_r2_to=&require_review_by_client_from=&require_review_by_client_to=&qc_qm_date_complete_from=&qc_qm_date_complete_to=&created_from=&created_to=&modified_from=&modified_to=&range_field=&range_value=&sort=&direction="

##Where to put the log files
$error_log = "$($log_dir)\error_log.txt"    #defining the error log path
$del_log = "$($log_dir)\delivery_log.txt"      #defining the error log path
$Index_txt = "$($upload_path)\File Count List.txt"
$total_count = "total.txt"

##############################

#initate a list for photosets
$SetID = @()
$listings = @()
$listings_list = @()
$tracker_err_list = @()
$cover_err_list = @()
$delivered_list = @()
$listing_count = @{}
#count number of errors for reporting
$total_errors = 0
$tracker_err = 0
$cover_err = 0
$delivered = 0
$progress = 0
$error_count = 0
#Silence Error to display on screen
$ErrorActionPreference= 'silentlycontinue'
##############################

#Status Bar
$stat = ("Reading CSV File", "Copying Exports to Upload Folder", "Comparing CS Export to Ready for Client", "Checking Missing Covers", "Writing to log files", "Changing Status on CS", "Archiving Delivered", "Done")

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
    Write-Progress -Id 1 -Activity "Airbnb Client Delivery" -status "$($stat[$n]) $($percentage)%" -PercentComplete $percentage
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

#### Copy and rename listings from Ready for Client to Upload  ####
function listings-copy {
    Foreach ($listing in $listings) {
        $listing_id = extract-id $listing
        $listings_list += $listing_id
        $source = "$($client_path)\$($listing)\Export\*"
        $dest = "$($upload_path)\Retouched JPEGs ($($listing_id))\"
        if (-Not (Test-Path $dest -PathType Container)) {
            New-Item -ItemType directory -Path $dest | Out-Null
        }
        Start-Job -Name "Listing Copying" -ScriptBlock {
            param($source, $dest)
            Copy-Item $source $dest -Recurse -Force
        } -ArgumentList $source, $dest | Out-Null
        copy-progress $source $dest "copy"
    }
}

################################################################################################

#### Copy and rename listings from Ready for Client to Upload  ####
function listings-archive {
    Foreach ($listing in $listings){
        $id = extract-id $listing
        if ($delivered_list -like $id) {
            $source = "$($client_path)\$($listing)"
            $dest = "$($archive_path)\$($archive_name)\"
            Start-Job -Name "Moving Items" -ScriptBlock {
                param($source, $dest)
                Move-Item -Path $source -Destination $dest -Force
            } -ArgumentList $source, $dest | Out-Null
            copy-progress $source $dest "move"
        }
    }
}

################################################################################################

#### Cheat Sheet File ####

function log-count {
    Set-Content -path $Index_txt -Value ">>>Cheat Sheet Upload Index File<<< `r`n"
    Add-Content -path $Index_txt -Value "_________________________________"
    Add-Content -path $Index_txt -Value ">Total Number of Folders: $($delivered)"
    Add-Content -path $Index_txt -Value "_________________________________"
    Add-Content -path $Index_txt -Value "`r"
    $output = '{0,-10} : {1,5}' -f "Set ID", "Count"
    Add-Content -path $Index_txt -Value $output
    Foreach ($key in $listing_count.Keys) {
        $output = '{0,-10} : {1,5}' -f $key, $listing_count[$key]
        Add-Content -path $Index_txt -Value $output
        }
    Add-Content -path $Index_txt -Value "_________________________________"
    Add-Content -path $Index_txt -Value "`r"
    Add-Content -path $Index_txt -Value ">>>>End of file"
}
################################################################################################

#### Error Log File ####

function log-error {
    Set-Content -path $error_log -Value ">>>Delivery Check Errors Log<<< `r`n"
    Add-Content -path $error_log -Value "_________________________________"
    Add-Content -path $error_log -Value ">>>Total Number of Errors: $($total_errors)"
    Add-Content -path $error_log -Value "_________________________________"
    Add-Content -path $error_log -Value "`r"
    Add-Content -path $error_log -Value ">Missing on Tracker: $($tracker_err)"
    Add-Content -path $error_log -Value "_________________________________"
    Add-Content -path $error_log -Value $tracker_err_list
    Add-Content -path $error_log -Value "_________________________________"
    Add-Content -path $error_log -Value "`r"
    Add-Content -path $error_log -Value ">Missing Covers: $($cover_err)"
    Add-Content -path $error_log -Value "_________________________________"
    Add-Content -path $error_log -Value $cover_err_list
    Add-Content -path $error_log -Value "_________________________________"
    Add-Content -path $error_log -Value "`r"
    Add-Content -path $error_log -Value ">>>>End of file"
}
################################################################################################

#### Delivered Log File ####

function log-delivery {
    Set-Content -path $del_log -Value ">>>Delivered Successfully Log<<< `r`n"
    Add-Content -path $del_log -Value "_________________________________"
    Add-Content -path $del_log -Value ">Total Delivered: $($delivered)"
    Add-Content -path $del_log -Value "_________________________________"
    Add-Content -path $del_log -Value "`r"
    Add-Content -path $del_log -Value ">List of Listings:"
    Add-Content -path $del_log -Value "_________________________________"
    Add-Content -path $del_log -Value $delivered_list
    Add-Content -path $del_log -Value "_________________________________"
    Add-Content -path $del_log -Value "`r"
    Add-Content -path $del_log -Value ">>>>End of file :)"
}

################################################################################################

#### MassUpdater Output File ####
function massupdater {
    $header = [PSCustomObject] @{external_id = $delivered_list[0]; status = 'Sent to client'}
    $header | Export-Csv -Path $massupdater -NoTypeInformation
    $i = 1
    While ( $i -lt $delivered_list.Count) {
        $content = [PSCustomObject] @{external_id = $delivered_list[$i]; status = 'Sent to client'}
        $content | Export-Csv -Path $massupdater -Append -NoTypeInformation
        $i += 1
    }
}

################################################################################################

#### Download CSV Export File ####
function Download-CSV {
    $timeout = 20
    Write-Host "Downloading CSV File"
    Start-Process($export_link) -WindowStyle Hidden
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
        Exit
    }
}


################################################################################################
#### Main Body ###

##Clear space for progress bar
"`r `n `r `n `r `n `r `n `r `n `r `n `n `n `n `n `n"

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

##Stage 2: Copying -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Ready, Copy and rename listings from Ready for Client to Upload
$listings = Get-ChildItem -Directory $client_path
listings-copy

##Stage 3: Comparing CS Export to Ready for Client -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Check that all folder ids exist in the SetIds exported from CS
Foreach ($id in $listings_list) {
    if (-Not ($SetID -like "$id*")) {
        $tracker_err_list += $id
        $tracker_err += 1
    }
}

##Count and list all Sets to be delivered
$delivery_count = Get-ChildItem -Directory "$($upload_path)\*" -Exclude "Missing Covers"| Measure-Object | %{$_.Count}
$folders = Get-ChildItem -Directory $upload_path

##Stage 4: Check Missing Covers -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Check for missing covers and write total counts to each Set folder
Foreach ($folder in $folders) {
    if (-Not ($folder -like "Missing Covers")) {
	    ##Write total file to folders
        $assets_count = Get-ChildItem -File "$($upload_path)\$($folder)\*" -exclude *.txt | Measure-Object | %{$_.Count}                   #count number of assets per listing
        Set-Content "$($upload_path)\$($folder)\$($total_count)" -Value $assets_count

        ##Check primary and vertical covers
	    $primary_check = Get-ChildItem -File "$($upload_path)\$($folder)\*" -filter "*_primary_0_0*" | Measure-Object | %{$_.Count}        #check for primary cover
	    $vertical_check = Get-ChildItem -File "$($upload_path)\$($folder)\*" -filter "*_vertical_0_0*" | Measure-Object | %{$_.Count}      #check for vertical cover

        If (($primary_check -eq 1) -and ($vertical_check -eq 1)) {
        ##Passed check add it to delivery list
            $id = extract-id $folder
            $delivered_list += $id
            $listing_count.Add( $id, $assets_count)
        } Else {
        ##Failed check move it to the error folder to exclude from auto delivery
            $cover_err += 1
            $id = extract-id $folder
            $cover_err_list += $id
            if (-Not (Test-Path $missing_covers -PathType Container)) {
                New-Item -ItemType directory -Path "$($missing_covers)" | Out-Null
            }
            $source = "$($upload_path)\$($folder)"
            $dest = "$($missing_covers)\$($folder)"
            Start-Job -Name "Missing Move" -ScriptBlock {
                param($source, $dest, $missing_covers)
                if (-Not (Test-Path $dest -PathType Container)) {
                    Move-Item -Path $source -Destination "$($missing_covers)\" -Force
                } Else {
                    Copy-Item "$($source)\*" "$($dest)\" -Recurse -Force
                    Remove-Item -Path $source -Recurse -Force
                }

            } -ArgumentList $source, $dest, $missing_covers | Out-Null
            copy-progress $source $dest "move"
	    }
    }
}

##Final count of ready for delivery and accumulating errors
$delivered = $delivered_list.Count
$total_errors = $tracker_err + $cover_err

##Stage 5: Write Log files -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Write log files
log-delivery
log-error
log-count
massupdater


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
if (-Not (Test-Path "$($archive_path)\$($archive_name)" -PathType Container)) {
            New-Item -ItemType directory -Path "$($archive_path)\$($archive_name)" | Out-Null
        }

##Archive sets
listings-archive

##Stage 7: End Process -> Update Progress
$progress += 1
$error_count = show-progress $progress $error_count

##Pop-up window to confirm process complete
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("ABB Client Deivery Completed",0,"Done",0x1)

########################################### Client Delivery Script###########################################
