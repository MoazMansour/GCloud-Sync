###############################################################################
# NAME:      ChangeConfig-V11.ps1
# AUTHOR:    Moaz Mansour
# E-MAIL:	   moaz.mansour@gmail.com
# DATE:      01/31/2019
# LANG:      PowerShell
#
# This script is the user interface to change ReadyForClient config.
#
# VERSION HISTORY:
# 1.0    01/10/2019    Initial Version
###############################################################################

#####################################################
############## Trulia Change Config #################
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

################################################################################################
#### Main Menu Options ####
function main-menu {
  Write-Host "################## Config Main Menu ####################"
  "`r"
  Write-Host "Please pick the type of change you would like to make:"
  Write-Host "[1] : " -ForegroundColor Green -NoNewline
  Write-Host "Change Credentials"
  Write-Host "[2] : " -ForegroundColor Green -NoNewline
  Write-Host "Change Path Variables"
  Write-Host "[0] : " -ForegroundColor Green -NoNewline
  Write-Host "Back"
  "`r"
  do {
    $in = Read-host "Input your option"
    Switch ($in)
    {
     1 {change-credentials}
     2 {change-path}
     0 {
       Write-Host "Ok, Roger That!" -ForegroundColor Yellow
       "`r"
       Exit
      }
     Default {
       "`r"
       Write-Host "Oops, I only need a number between 1 and 3" -ForegroundColor Red
       "`r"
     }
   }
 } while($in -notmatch "012")
}

################################################################################################
#### Ending Menu Options ####
function extra_menu {
  do {
    Write-Host "Would you like to change something else " -ForegroundColor Yellow -NoNewline
    $in = Read-Host "[Y/N]?"
    Switch ($in) {
      "Y" {
        read_config
        main-menu
      }
      "N" {
        "`r"
        Write-Host "Ok, Roger that!" -ForegroundColor Yellow
        Exit
      }
      Default {
        "`r"
        Write-Host "Oops, I only take a Y or N" -ForegroundColor Red
        "`r"
      }
    }
  } while ($in -notmatch "YyNn")
}

################################################################################################
#### Chane Credentials Menu Options ####
function change-credentials {
  "`r"
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
  $replacment = $replacment -replace "change_flag;TRUE","change_flag;FALSE"
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
    Write-Host "Current Chrome Download Location: $($csv_loc)"
    $new_csv_loc = Read-Host "New Chrome Download Location"
    $reg_csv_loc = [Regex]::Escape($csv_loc)
    ## Saving to config file
    $replacment = $replacment -replace "csv_loc;$($reg_csv_loc)","csv_loc;$($new_csv_loc)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 2) {
    Write-Host "Current DAM-PostProduction Path: $($dam_path)"
    $new_dam_path = Read-Host "New DAM-PostProduction Path"
    $reg_dam_path = [Regex]::Escape($dam_path)
    ## Saving to config file
    $replacment = $replacment -replace "dam_path;$($reg_dam_path)","dam_path;$($new_dam_path)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 3) {
    Write-Host "Current Local Trulia Folder Path: $($local_path)"
    $new_local_path = Read-Host "New Local Trulia Path"
    $reg_local_path = [Regex]::Escape($local_path)
    ## Saving to config file
    $replacment = $replacment -replace "local_path;$($reg_local_path)","local_path;$($new_local_path)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 4) {
    Write-Host "Current CS CSV Export: $($export_link)"
    $new_export_link = Read-Host "New CS CSV Export"
    $reg_export_link = [Regex]::Escape($export_link)
    ## Saving to config file
    $replacment = $replacment -replace "export_link;$($reg_export_link)","export_link;$($new_export_link)"
    Set-Content -Path $config_file -Value $replacment
  } ElseIf ($n -eq 5) {
    Write-Host "Current Master Catalog Path: $($master_path)"
    $new_master_path = Read-Host "New Master Catalog Path"
    $reg_master_path = [Regex]::Escape($master_path)
    ## Saving to config file
    $replacment = $replacment -replace "master_path;$($reg_master_path)","master_path;$($new_master_path)"
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
  "`r"
  Write-Host "################## Change Path Variables ####################"
  "`r"
  Write-Host "Please pick the type of change you would like to make:"
  Write-Host "[1]  : " -ForegroundColor Green -NoNewline
  Write-Host "Chrome Default Download Location"
  Write-Host "[2]  : " -ForegroundColor Green -NoNewline
  Write-Host "DAM-PostProduction Path"
  Write-Host "[3]  : " -ForegroundColor Green -NoNewline
  Write-Host "Local Trulia Folder Path"
  Write-Host "[4]  : " -ForegroundColor Green -NoNewline
  Write-Host "CS CSV Export Link"
  Write-Host "[5]  : " -ForegroundColor Green -NoNewline
  Write-Host "Master Catalog Path"
  "`r"
  ##
  $flag = 8
  While ($flag -eq 8){
    $read = Read-Host "Input your option"
    $in = [int]$read
    if (($in -le 5) -and ($in -gt 0)){
      $flag = 0
      do_change $in
    }
    Else {
      "`r"
      Write-Host "Oops, I only need a number between 1 and 3" -ForegroundColor Red
      "`r"
    }
  }
}

################################################################################################
##Clear space for progress bar
"`r"
Write-Host "########################################################"
Write-Host "################## Change Config UI ####################"
Write-Host "########################################################"
"`r `n `r `n `r"

##call the main menu
read_config
main-menu

"`r `n `r"
