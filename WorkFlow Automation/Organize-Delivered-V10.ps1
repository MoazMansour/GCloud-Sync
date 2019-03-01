###############################################################################
# NAME:      Organize-Delivered-V10.ps1
# AUTHOR:    Moaz Mansour
# E-MAIL:	   moaz.mansour@gmail.com
# DATE:      01/07/2019
# LANG:      PowerShell
#
# This script organizes the scattered home listings folder in the delivered archive.
#
# VERSION HISTORY:
# 1.0    01/07/2019    Initial Version
###############################################################################

###################################################################
################## Delivered Folder Organization ##################
###################################################################

$path = "C:\Users\Blink Workstation\Desktop\New folder"
$listings = @()
$folders = @()
$folders = Get-ChildItem -Directory $path -Exclude "Home*"
$listings = Get-ChildItem -Directory $path -Filter "Home*"
ForEach ($list in $listings){
    Write-Host "$($list): " -NoNewline
    Write-Host $list.LastWriteTime
    $pattern = '(\d+/\d+/\d\d\d\d)'
    $check = $list.LastWriteTime -match $pattern
    $mdate = $matches[0]
    $mdate = $mdate -replace "/", "-"
    $dest = "$($path)\$($mdate)"
    if(-Not (Test-Path $dest -PathType Container)){
        New-Item -ItemType directory -Path "$($dest)" | Out-Null
    }
    Move-Item -Path "$($path)\$($list)" -Destination "$($dest)\$($list)" -Force
    Write-Host $mdate
}
