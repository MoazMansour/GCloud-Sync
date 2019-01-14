###############################################################################
# NAME:      ChangeConfig-V10.ps1
# AUTHOR:    Moaz Mansour, Blink
# E-MAIL:    moaz.mansour@blink.la
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
  $in = Read-Host "Input your option"
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
