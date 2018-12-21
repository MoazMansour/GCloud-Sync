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
# 1.1    12/21/2018    Includes MassUpdater
###############################################################################

#####################################################
################## Client Delivery ##################
#####################################################

##Directories path parameters
$csv_path = "C:\Users\Blink Workstation\Downloads\photo_sets.csv"
$client_path = "Z:\Auto test"
$upload_path = "Y:\Client\Airbnb\Plus\00 - DARYL Pull\Auto Test"
$missing_covers = "$($upload_path)\Missing Covers"
$archive_path = "Y:\Client\Airbnb\Plus\Delivered Test"

##Where to put the log files
$error_log = "C:\Users\Blink Workstation\Downloads\error_log.txt"    #defining the error log path
$del_log = "C:\Users\Blink Workstation\Downloads\delivery_log.txt"      #defining the error log path
$Index_txt = "$($upload_path)\File Count List.txt"
$total_count = "total.txt"
$massupdater = "C:\Users\Blink Workstation\Downloads\MassUpdater.csv"
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
##############################

#Status Bar
$stat = ("Reading CSV File", "Copying Exports to Upload Folder", "Comparing CS Export to Ready for Client", "Checking Missing Covers", "Writing to log files", "Archiving Delivered", "Done")

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
    param([int]$n)
    $percentage = [math]::Truncate(($n+1)/$stat.count*100)
    Write-Progress -Id 1 -Activity "Airbnb Client Delivery" -status "$($stat[$n]) $($percentage)%" -PercentComplete $percentage
    if (-Not ($n -eq 0)) {
        Write-Host "[Done] : $($stat[($n-1)])"
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
#### Main Body ###

##Stage 1: Reading CSV -> Update Progress
show-progress $progress
"`r `n `r `n `r `n `r `n `r `n `r `n `n `n `n `n `n"

##Read Set Ids from the CSV file
Import-Csv $csv_path |`
    ForEach-Object {
        $SetID += $_."Photo set ID"
    }

##Stage 2: Copying -> Update Progress
$progress += 1
show-progress $progress

##Ready, Copy and rename listings from Ready for Client to Upload
$listings = Get-ChildItem -Directory $client_path
listings-copy

##Stage 3: Comparing CS Export to Ready for Client -> Update Progress
$progress += 1
show-progress $progress

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
show-progress $progress

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
show-progress $progress

##Write log files
log-delivery
log-error
log-count
massupdater


##Stage 6: Archiving -> Update Progress
$progress += 1
show-progress $progress

##Create Archive Folder
$archive_name = Get-Date -UFormat "%m-%d-%Y"
if (-Not (Test-Path "$($archive_path)\$($archive_name)" -PathType Container)) {
            New-Item -ItemType directory -Path "$($archive_path)\$($archive_name)" | Out-Null
        }

##Archive sets
listings-archive

##Stage 7: End Process -> Update Progress
$progress += 1
show-progress $progress

##Pop-up window to confirm process complete
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("ABB Client Deivery Completed",0,"Done",0x1)

########################################### Client Delivery Script###########################################
