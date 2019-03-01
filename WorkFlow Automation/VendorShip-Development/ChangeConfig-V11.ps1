###############################################################################
# NAME:      ChangeConfig-V11.ps1
# AUTHOR:    Moaz Mansour
# E-MAIL:	   moaz.mansour@gmail.com
# DATE:      01/10/2019
# LANG:      PowerShell
#
# This script is the user interface to change ReadyForClient config.
#
# VERSION HISTORY:
# 1.0    01/10/2019    Initial Version
# 1.1    01/29/2019    Includes Vendor Shipping Variables
###############################################################################

#####################################################
################## Change Config ####################
#####################################################

#Global Variables
$current_loc = Get-Location
$config_file = "$($current_loc)\config.txt"
$vendor_config = "$($current_loc)\vendor_config.txt"
$list_team_numbers = @()
$list_team_names = @()
$list_team_default = @()
$list_team_paths = @()

#Silence Error to display on screen
$ErrorActionPreference= 'silentlycontinue'

################################################################################################
#### Read Config File ####
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
##

################################################################################################
#### Main Menu Options ####

function main-menu {
  Write-Host "################## Main Menu ####################"
  "`r"
  Write-Host "Please pick the type of change you would like to make:"
  Write-Host "[1] : " -ForegroundColor Green -NoNewline
  Write-Host "Change Credentials"
  Write-Host "[2] : " -ForegroundColor Green -NoNewline
  Write-Host "Change Path Variables"
  Write-Host "[3] : " -ForegroundColor Green -NoNewline
  Write-Host "Change Vendor Data"
  Write-Host "[0] : " -ForegroundColor Green -NoNewline
  Write-Host "Exit"
  "`r"
  $flag = 8
  While ($flag -eq 8){
    $in = Read-Host "Input your option"
    if ($in -eq 1){
      $flag = 0
      "`r"
      change-credentials
    } ElseIf ($in -eq 2){
      $flag = 0
      "`r"
      change-path
    } ElseIf ($in -eq 3){
      $flag = 0
      "`r"
      change-vendor
    } ElseIf ($in -eq 0) {
      "`r"
      Write-Host "Good Bye!" -ForegroundColor Yellow
      Exit
    } Else {
      "`r"
      Write-Host "Error: Please type in a number between 0 to 3" -ForegroundColor Red
    }
  }
}

################################################################################################
#### Ending Menu Options ####
function extra_menu {
  $in = Read-Host "Would you like to do something else [Y/N]?"
  If (($in -eq "y") -or ($in -eq "Y")) {
    "`r"
    read_config
    main-menu
  } Else {
    Write-Host "Good Bye!" -ForegroundColor Yellow
    Exit
  }
}

################################################################################################
#### Chane Credentials Menu Options ####

function change-credentials {
  Write-Host "################## Change Credentials ####################"
  "`r"
  Write-Host "Current username: $($username)"
  $new_user = Read-Host "New username"
  $new_pass = Read-Host "New Password" -AsSecureString
  ## Encoding Password
  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($new_pass)
  $TP = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  $bytes_pass = [System.Text.Encoding]::UTF8.GetBytes($TP)
  $encoded_pass = [System.Convert]::ToBase64String($bytes_pass)
  ## Saving to config file
  $replacment = $replacment -replace "username;$($username)","username;$($new_user)"
  $replacment = $replacment -replace "password;$($password)","password;$($encoded_pass)"
  Set-Content -Path $config_file -Value $replacment
  "`r `n `r"
  Write-Host "Credentials Updated Successfully" -ForegroundColor Green
  "`r"
  extra_menu
}

################################################################################################
#### Do Change function Options ####

function do_change($n) {
  if ($n -eq 1){
    Write-Host "Current CSV Download Path: $($csv_loc)"
    $new_csv_loc = Read-Host "New CSV Download Path"
    $reg_csv_loc = [Regex]::Escape($csv_loc)
    ## Saving to config file
    $replacment = $replacment -replace "csv_loc;$($reg_csv_loc)","csv_loc;$($new_csv_loc)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 2) {
    Write-Host "Current Ready for Client Path: $($client_path)"
    $new_client_path = Read-Host "New Ready for Client Path"
    $reg_client_path = [Regex]::Escape($client_path)
    ## Saving to config file
    $replacment = $replacment -replace "client_path;$($reg_client_path)","client_path;$($new_client_path)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 3) {
    Write-Host "Current Upload Folder Path: $($upload_path)"
    $new_upload_path = Read-Host "New Upload Path"
    $reg_upload_path = [Regex]::Escape($upload_path)
    ## Saving to config file
    $replacment = $replacment -replace "upload_path;$($reg_upload_path)","upload_path;$($new_upload_path)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 4) {
    Write-Host "Current Delivered Archive Path: $($archive_path)"
    $new_archive_path = Read-Host "New Delivered Archive Path"
    $reg_archive_path = [Regex]::Escape($archive_path)
    ## Saving to config file
    $replacment = $replacment -replace "archive_path;$($reg_archive_path)","archive_path;$($new_archive_path)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 5) {
    Write-Host "Current Massupdater Destination: $($massupdater)"
    $new_massupdater = Read-Host "New Massupdater Destination"
    $reg_massupdater = [Regex]::Escape($massupdater)
    ## Saving to config file
    $replacment = $replacment -replace "massupdater;$($reg_massupdater)","massupdater;$($new_massupdater)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 6) {
    Write-Host "Current Log Files Destination: $($log_dir)"
    $new_log_dir = Read-Host "New Log Files Destination"
    $reg_log_dir = [Regex]::Escape($log_dir)
    ## Saving to config file
    $replacment = $replacment -replace "log_dir;$($reg_log_dir)","log_dir;$($new_log_dir)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 7) {
    Write-Host "Current Client Delivery CSV Export Link: $($export_link)"
    $new_export_link = Read-Host "New Client Delivery CSV Export Link"
    $reg_export_link = [Regex]::Escape($export_link)
    ## Saving to config file
    $replacment = $replacment -replace "export_link;$($reg_export_link)","export_link;$($new_export_link)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 8) {
    Write-Host "Current Massupdater Upload Link: $($cs_upload)"
    $new_cs_upload = Read-Host "New Massupdater Upload Link"
    $reg_cs_upload = [Regex]::Escape($cs_upload)
    ## Saving to config file
    $replacment = $replacment -replace "cs_upload;$($reg_cs_upload)","cs_upload;$($new_cs_upload)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 9) {
    Write-Host "Current Ready for Vendor Path: $($ready_path)"
    $new_ready_path = Read-Host "New Ready for Vendor Path"
    $reg_ready_path = [Regex]::Escape($ready_path)
    ## Saving to config file
    $replacment = $replacment -replace "ready_path;$($reg_ready_path)","ready_path;$($new_ready_path)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 10) {
    Write-Host "Current Local folder for Vendor Selects Path: $($select_path)"
    $new_select_path = Read-Host "New Local folder for Vendor Selects Path"
    $reg_select_path = [Regex]::Escape($select_path)
    ## Saving to config file
    $replacment = $replacment -replace "select_path;$($reg_select_path)","select_path;$($new_select_path)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 11) {
    Write-Host "Current Sent to Vendor Archive Path: $($vendor_archive_path)"
    $new_vendor_archive_path = Read-Host "New Sent to Vendor Archive Path"
    $reg_vendor_archive_path = [Regex]::Escape($vendor_archive_path)
    ## Saving to config file
    $replacment = $replacment -replace "vendor_archive_path;$($reg_vendor_archive_path)","vendor_archive_path;$($new_vendor_archive_path)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 12) {
    Write-Host "Current Vendor Shippment CSV Export Link: $($ready_link)"
    $new_ready_link = Read-Host "New Vendor Shippment CSV Export Link"
    $reg_ready_link = [Regex]::Escape($ready_link)
    ## Saving to config file
    $replacment = $replacment -replace "ready_link;$($reg_ready_link)","ready_link;$($new_ready_link)"
    Set-Content -Path $config_file -Value $replacment
  }
  "`r `n `r"
  Write-Host "Path Changes Updated Successfully" -ForegroundColor Green
  "`r"
  extra_menu
}

################################################################################################
#### Change Paths Menu Options ####

function change-path {
  Write-Host "################## Change Path Variables ####################"
  "`r"
  Write-Host "Please pick the type of change you would like to make:"
  Write-Host "[1]  : " -ForegroundColor Green -NoNewline
  Write-Host "CSV Export Download Location (For both Vendor & Client)"
  Write-Host "[2]  : " -ForegroundColor Green -NoNewline
  Write-Host "Ready for Client Path"
  Write-Host "[3]  : " -ForegroundColor Green -NoNewline
  Write-Host "Upload Folder Path"
  Write-Host "[4]  : " -ForegroundColor Green -NoNewline
  Write-Host "Delivered Archive Folder Path"
  Write-Host "[5]  : " -ForegroundColor Green -NoNewline
  Write-Host "Massupdater Destination (For both Vendor & Client)"
  Write-Host "[6]  : " -ForegroundColor Green -NoNewline
  Write-Host "Log Files Destination (For both Vendor & Client)"
  Write-Host "[7]  : " -ForegroundColor Green -NoNewline
  Write-Host "Client Delivery CSV Export Link"
  Write-Host "[8]  : " -ForegroundColor Green -NoNewline
  Write-Host "Massupdater Upload Link (For both Vendor & Client)"
  Write-Host "[9]  : " -ForegroundColor Green -NoNewline
  Write-Host "Ready for Vendor Path"
  Write-Host "[10] : " -ForegroundColor Green -NoNewline
  Write-Host "Local Folder for Vendor Selects Path"
  Write-Host "[11] : " -ForegroundColor Green -NoNewline
  Write-Host "Sent to Vendor Archive Path"
  Write-Host "[12] : " -ForegroundColor Green -NoNewline
  Write-Host "Vendor Shippment CSV Export Link"
  "`r"
  ##
  $flag = 8
  While ($flag -eq 8){
    $read = Read-Host "Input your option"
    $in = [int]$read
    if (($in -le 12) -and ($in -gt 0)){
      $flag = 0
      do_change $in
    }
    Else {
      "`r"
      Write-Host "Error: Please type in an int between 1 to 12" -ForegroundColor Red
    }
  }
}

################################################################################################
#### Change Vendor Menu Options ####
function change-vendor {
  Write-Host "################## Change Vendor Info ####################"
  "`r"
  Write-Host "Hi, here below is the list of vendors we have so far and their default assignments"
  "`r"
  $i = 0
  While ($i -lt $list_team_numbers.count) {
    $output = '{0,-7} ({1,-12}) > {2,5} > {3}' -f $list_team_numbers[$i], $list_team_names[$i], $list_team_default[$i], $list_team_paths[$i]
    Write-Host "$($output)"
    $i += 1
  }
  "`r"
  Write-Host "Please pick the type of change you would like to make:"
  Write-Host "[1]  : " -ForegroundColor Green -NoNewline
  Write-Host "Add Vendor"
  Write-Host "[2]  : " -ForegroundColor Green -NoNewline
  Write-Host "Remove Vendor"
  Write-Host "[3]  : " -ForegroundColor Green -NoNewline
  Write-Host "Update Vendor"
  "`r"
  ##
  $flag = 8
  While ($flag -eq 8){
    $read = Read-Host "Input your option"
    $in = [int]$read
    if (($in -le 3) -and ($in -gt 0)){
      $flag = 0
      vendor_action $in
    }
    Else {
      "`r"
      Write-Host "Error: Please type in an int between 1 to 3" -ForegroundColor Red
    }
  }
}

################################################################################################
#### Remove Vendor Menu ####
function remove_vendor_menu($element) {
  Write-Host "Are you sure you want to REMOVE the below vendor?" -ForegroundColor Yellow
  $key = $Global:list_team_numbers.indexof($element)
  $output = '{0,-7} ({1,-12}) > {2,5} > {3}' -f $list_team_numbers[$key], $list_team_names[$key], $list_team_default[$key], $list_team_paths[$key]
  "`r"
  Write-Host "$($output)"
  "`r"
  $flag = 8
  While ($flag -eq 8){
    $in = Read-Host "Confirm [Y/N]?"
    if (($in -eq "Y") -or ($in -eq "y")){
      $flag = 0
      $Global:list_team_numbers = [System.Collections.ArrayList]$Global:list_team_numbers
      $Global:list_team_names = [System.Collections.ArrayList]$Global:list_team_names
      $Global:list_team_paths = [System.Collections.ArrayList]$Global:list_team_paths
      $Global:list_team_default = [System.Collections.ArrayList]$Global:list_team_default

      $Global:list_team_numbers.RemoveAt($key)
      $Global:list_team_names.RemoveAt($key)
      $Global:list_team_paths.RemoveAt($key)
      $Global:list_team_default.RemoveAt($key)
    } ElseIf (($in -eq "N") -or ($in -eq "n")){
      $flag = 0
    } Else {
      "`r"
      Write-Host "Oops, This only takes a Y or N" -ForegroundColor Red
    }
  }
}

################################################################################################
#### Update Vendor Menu ####
function update_vendor_menu($element) {
  "`r"
  Write-Host "What would you like to change for the below vendor?" -ForegroundColor Yellow
  $key = $Global:list_team_numbers.indexof($element)
  $output = '{0,-7} ({1,-12}) > {2,5} > {3}' -f $list_team_numbers[$key], $list_team_names[$key], $list_team_default[$key], $list_team_paths[$key]
  "`r"
  Write-Host "$($output)"
  "`r"
  Write-Host "[1] : " -ForegroundColor Green -NoNewline
  Write-Host "Change Team Number"
  Write-Host "[2] : " -ForegroundColor Green -NoNewline
  Write-Host "Change Team Name"
  Write-Host "[3] : " -ForegroundColor Green -NoNewline
  Write-Host "Change Team Default Assignment"
  Write-Host "[4] : " -ForegroundColor Green -NoNewline
  Write-Host "Change Team Path"
  "`r"
  $flag = 8
  While ($flag -eq 8){
    $in = Read-Host "Input your option"
    if ($in -eq 1){
      $flag = 0
      "`r"
      Write-Host "Ok, sure." -ForegroundColor Yellow
      $q = 8
      While ($q -eq 8) {
        $in = Read-Host "New Team # "
        if ($in -match '^[0-9]*$'){
          $element = "Team $($in)"
          if ($Global:list_team_numbers -like $element) {
             Write-Host "Oops, this team already exists. Please enter a diff number" -ForegroundColor Red
          } Else {
              $Global:list_team_numbers[$key] = $element
              $q = 0
          }
        } Else {
          "`r"
          Write-Host "Oops, please just add the team number (eg. 8)" -ForegroundColor Red
        }
      }
    } ElseIf ($in -eq 2){
      $flag = 0
      "`r"
      Write-Host "Ok, sure." -ForegroundColor Yellow
      $q = 8
      While ($q -eq 8) {
          $in = Read-Host "New Team Name "
          if ($Global:list_team_names -like $in){
              Write-Host "Oops, this team already exists. Please enter a diff name" -ForegroundColor Red
          } Else {
              $Global:list_team_names[$key] = $in
              $q = 0
          }
      }
    } ElseIf ($in -eq 3){
      $flag = 0
      "`r"
      Write-Host "Ok, sure." -ForegroundColor Yellow
      $q = 8
      While ($q -eq 8) {
        $in = Read-Host "New Default Assignment "
        if ($in -match '^[0-9]*$'){
          $q = 0
          $element = [int]$in
          $Global:list_team_default[$key] = $element
        } Else {
          "`r"
          Write-Host "Oops, please input an integer (eg. 5)" -ForegroundColor Red
        }
      }
    } ElseIf ($in -eq 4) {
      $flag = 0
      "`r"
      Write-Host "Ok, sure." -ForegroundColor Yellow
      $q = 8
      While ($q -eq 8) {
          $in = Read-Host "New Team Path "
          if ($Global:list_team_paths -like $in){
              Write-Host "Oops, this path already exists. Please enter a diff path" -ForegroundColor Red
          } Else {
              $Global:list_team_paths[$key] = $in
              $q = 0
          }
        }
    } Else {
      "`r"
      Write-Host "Error: Please type in a number between 1 and 4" -ForegroundColor Red
    }
  }
}

################################################################################################
#### Update Vendor Changes ####
function update_vendor {
    $new_team_numbers = $Global:list_team_numbers -join ","
    $new_team_names = $Global:list_team_names -join ","
    $new_team_paths = $Global:list_team_paths -join ","
    $new_team_default = $Global:list_team_default -join ","

    $reg_team_numbers = [Regex]::Escape($team_numbers)
    $reg_team_names = [Regex]::Escape($team_names)
    $reg_team_paths = [Regex]::Escape($team_paths)
    $reg_team_default = [Regex]::Escape($team_default)

    $Global:replacment = $Global:replacment -replace "team_numbers;$($reg_team_numbers)","team_numbers;$($new_team_numbers)"
    $Global:replacment = $Global:replacment -replace "team_names;$($reg_team_names)","team_names;$($new_team_names)"
    $Global:replacment = $Global:replacment -replace "team_paths;$($reg_team_paths)","team_paths;$($new_team_paths)"
    $Global:replacment = $Global:replacment -replace "team_default;$($reg_team_default)","team_default;$($new_team_default)"
    Set-Content -Path $config_file -Value $Global:replacment
}

################################################################################################
#### Vendor Change into Action ####
function vendor_action($n) {
  "`r"
  if ($n -eq 1) {
    Write-Host "You are about to ADD a new vendor:" -ForegroundColor Yellow
    "`r"
    $flag = 8
    While ($flag -eq 8) {
      $in = Read-Host "Team # "
      if ($in -match '^[0-9]*$'){
        $element = "Team $($in)"
        if ($Global:list_team_numbers -like $element) {
           Write-Host "Oops, this team already exists. Please enter a diff number" -ForegroundColor Red
        } Else {
            $Global:list_team_numbers += $element
            $flag = 0
        }
      } Else {
        "`r"
        Write-Host "Oops, please just add the team number (eg. 8)" -ForegroundColor Red
      }
    }
    $flag = 8
    While ($flag -eq 8) {
        $in = Read-Host "Team Name "
        if ($Global:list_team_names -like $in){
            Write-Host "Oops, this team already exists. Please enter a diff name" -ForegroundColor Red
        } Else {
            $Global:list_team_names += $in
            $flag = 0
        }
    }
    $flag = 8
    While ($flag -eq 8) {
      $in = Read-Host "Default Assignment "
      if ($in -match '^[0-9]*$'){
        $flag = 0
        $element = [int]$in
        $Global:list_team_default += $element
      } Else {
        "`r"
        Write-Host "Oops, please input an integer (eg. 5)" -ForegroundColor Red
      }
    }
    $flag = 8
    While ($flag -eq 8) {
        $in = Read-Host "Team Path "
        if ($Global:list_team_paths -like $in){
            Write-Host "Oops, this path already exists. Please enter a diff path" -ForegroundColor Red
        } Else {
            $Global:list_team_paths += $in
            $flag = 0
        }
    }
  } ElseIf ($n -eq 2) {
    Write-Host "You are about to REMOVE a vendor:" -ForegroundColor Yellow
    "`r"
    $flag = 8
    While ($flag -eq 8) {
      $in = Read-Host "Team # "
      if ($in -match '^[0-9]*$'){
        $element = "Team $($in)"
        if (-Not ($Global:list_team_numbers -like $element)) {
          Write-Host "Oops, this team does not exist. Please enter a diff number" -ForegroundColor Red
        } Else {
          remove_vendor_menu $element
          $flag = 0
        }
      } Else {
        "`r"
        Write-Host "Oops, please just add the team number (eg. 8)" -ForegroundColor Red
      }
    }
  } ElseIf ($n -eq 3) {
    Write-Host "You are about to UPDATE a vendor:" -ForegroundColor Yellow
    $flag = 8
    While ($flag -eq 8){
      $in = Read-Host "Team # "
      if ($in -match '^[0-9]*$'){
        $element = "Team $($in)"
        if (-Not ($Global:list_team_numbers -like $element)) {
          Write-Host "Oops, this team does not exist. Please enter a diff number" -ForegroundColor Red
        } Else {
          update_vendor_menu $element
          $flag  = 0
        }
      } Else {
        "`r"
        Write-Host "Oops, please just add the team number (eg. 8)" -ForegroundColor Red
      }
    }
  }
  update_vendor
  "`r `n `r"
  Write-Host "Vendor Changes Updated Successfully" -ForegroundColor Green
  "`r"
  extra_menu
}

################################################################################################
##Clear space for progress bar
"`r `n `r `n `r"
Write-Host "########################################################"
Write-Host "################## Change Config UI ####################"
Write-Host "########################################################"
"`r `n `r `n `r"

##call the main menu
read_config
Set-Variable -Name "list_team_names" -Value $team_names.Split(',') -Scope Global
Set-Variable -Name "list_team_paths" -Value $team_paths.Split(',') -Scope Global
Set-Variable -Name "list_team_numbers" -Value $team_numbers.Split(',') -Scope Global
Set-Variable -Name "list_team_default" -Value $team_default.Split(',') -Scope Global
main-menu

"`r `n `r"
