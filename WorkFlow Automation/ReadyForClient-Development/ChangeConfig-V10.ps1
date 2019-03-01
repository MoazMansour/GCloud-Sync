###############################################################################
# NAME:      ChangeConfig-V10.ps1
# AUTHOR:    Moaz Mansour
# E-MAIL:	   moaz.mansour@gmail.com
# DATE:      01/10/2019
# LANG:      PowerShell
#
# This script is the user interface to change ReadyForClient config.
#
# VERSION HISTORY:
# 1.0    01/10/2019    Initial Version
###############################################################################

#####################################################
################## Change Config ####################
#####################################################

#Global Variables
$current_loc = Get-Location
$config_file = "$($current_loc)\config.txt"

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
    } ElseIf ($in -eq 0) {
      "`r"
      Write-Host "Good Bye!" -ForegroundColor Yellow
      Exit
    } Else {
      "`r"
      Write-Host "Error: Please type in 1 or 2 only" -ForegroundColor Red
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
    Write-Host "Current Delivered Path: $($archive_path)"
    $new_archive_path = Read-Host "New Delivered Path"
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
    Write-Host "Current CS CSV Export Link: $($export_link)"
    $new_export_link = Read-Host "New CS CSV Export Link"
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
  }
  "`r `n `r"
  Write-Host "Path Changes Updated Successfully" -ForegroundColor Green
  "`r"
  extra_menu
}

################################################################################################
#### Chane Paths Menu Options ####

function change-path {
  Write-Host "################## Change Path Variables ####################"
  "`r"
  Write-Host "Please pick the type of change you would like to make:"
  Write-Host "[1] : " -ForegroundColor Green -NoNewline
  Write-Host "CSV Export Download Location"
  Write-Host "[2] : " -ForegroundColor Green -NoNewline
  Write-Host "Ready for Client"
  Write-Host "[3] : " -ForegroundColor Green -NoNewline
  Write-Host "Upload Folder Path"
  Write-Host "[4] : " -ForegroundColor Green -NoNewline
  Write-Host "Delivered Folder Path"
  Write-Host "[5] : " -ForegroundColor Green -NoNewline
  Write-Host "Massupdater Destination"
  Write-Host "[6] : " -ForegroundColor Green -NoNewline
  Write-Host "Log Files Destination"
  Write-Host "[7] : " -ForegroundColor Green -NoNewline
  Write-Host "CS CSV Export Link"
  Write-Host "[8] : " -ForegroundColor Green -NoNewline
  Write-Host "Massupdater Upload Link"
  "`r"
  ##
  $flag = 8
  While ($flag -eq 8){
    $in = Read-Host "Input your option"
    if (($in -le 8) -and ($in -gt 0)){
      $flag = 0
      do_change $in
    }
    Else {
      "`r"
      Write-Host "Error: Please type in an int between 1 to 8" -ForegroundColor Red
    }
  }
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
main-menu

"`r `n `r"
