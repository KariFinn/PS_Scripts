﻿# W10ImageUpdate.ps1 - A PS Script to update Windows image
# Use, edit & share as you wish (Public Domain)
# Kari The Finn 15-JUL-2017
# - TenForums.com/members/kari.html
# - Twitter.com/KariTheFinn
# - YouTube.com/KariTheFinn
#________________________________________________________________
    
##########################################################
# Create a temporary working folder C:\TempMount, delete
# old one first if folder with such name already exists
##########################################################

cls
$Mount = 'C:\TempMount\'
if (Test-Path $Mount) {Remove-Item $Mount}
$Mount = New-Item -ItemType Directory -Path $Mount

##########################################################
# Delete possible old log files from previous runs
##########################################################

if (Test-Path C:\WUSuccess.log) {Remove-Item C:\WUSuccess.log}
if (Test-Path C:\WUFail.log) {Remove-Item C:\WUFail.log}

##########################################################
# Prompt user for path to folder containing install.wim. 
# By default it's ISO_Folder\Sources, on dual architecture 
# media ISO_Folder\x64\Sources or ISO_Folder\x86\Sources
##########################################################

Write-Host
$WimFolder = Read-Host -Prompt 'Enter path to folder containing install.wim file'
$Wimfile = Join-Path $WimFolder '\install.wim'

##########################################################
# List Windows editions on image, prompt user for
# edition to be be updated
##########################################################

Get-WindowsImage -ImagePath $WimFile
Write-Host
$Index = Read-Host -Prompt 'Which edition should be updated (enter ImageIndex number)'

##########################################################
# Prompt user for folder containing downloaded WU files
# (*.cab and / or *.msu)
##########################################################

# Mount Windows image in temporary mount folder
##########################################################
# Write updates one by one to Windows image. If OK, add
# update name including KB number to WUSuccess.log file,
# if failed add to WUFail.log
##########################################################
# Dismount Windows image saving updated install.wim
##########################################################
# List updates added to Windows image
##########################################################

if (Test-Path C:\WUSuccess.log)
    {
    Write-Host
    Write-Host 'Following updates successfully added to Windows image: '
    $LogContent = Get-Content 'C:\WUSuccess.log'
    foreach ($Line in $LogContent)
        {Write-Host $Line}
    } 
    else
    {
    Write-Host
    Write-Host 'All updates failed, nothing added to Windows image.'}

##########################################################
# List failed updates
##########################################################

if (Test-Path C:\WUFail.log)
    {
    Write-Host
    Write-Host 'Following updates could not be added to Windows image: '
    $LogContent = Get-Content 'C:\WUfail.log'
    foreach ($Line in $LogContent)
        {Write-Host $Line}
    } 
    else
    {
    Write-Host
    Write-Host 'No failed updates.'}

##########################################################
# Delete temporary mount folder
##########################################################

Remove-Item $Mount