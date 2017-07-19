########################################################## 
# 
# W10ImageUpdate.ps1 - A PS Script to update Windows image
# 
# You are free to use, edit & share this script as long as
# source is mentioned.
#
# Kari The Finn 19-JUL-2017
# - TenForums.com/members/kari.html
# - Twitter.com/KariTheFinn
# - YouTube.com/KariTheFinn
#
##########################################################
   
##########################################################
# Show short instructions to user
##########################################################   

cls
Write-Host                                                                       
Write-Host ' This script will update Windows 10 install media with updates '
Write-Host ' downloaded from http://www.catalog.update.microsoft.com'
Write-Host 
Write-Host ' Please notice that the process will take quite some time, depending'
Write-Host ' on amount and size of updates being applied to Windows image. '
Write-Host
Write-Host ' Mount (double click) a Windows 10 ISO image and copy its content'
Write-Host ' to a folder on local PC, for instance "F:\MyISOFiles". Make sure the'
Write-Host ' folder has no other content than copied Windows install files.'
Write-Host 
Write-Host ' Alternatively, if you already have a bootable Windows 10 install'
Write-Host ' USB flash drive just plug it in. In this case you do not have to'
Write-Host ' copy anything to hard disk.'
Write-Host 
Write-Host ' When ISO files have been copied to a hard disk folder, or USB drive'
Write-Host ' has been plugged in, press Enter to start.'
Write-Host 
Write-Host ' Notice that you cannot use this script to update an ESD based install'
Write-Host ' media like for instance ISO / USB made with Media Creation Tool.'
Write-Host
pause
    
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
# Prompt user for path to folder containing installation 
# files, either a Windows install USB drive or folder user
# copied installation files to from mounted ISO image.
#
# Using 'while' loop to check that source given by user 
# contains a Windows image, if not user is asked to chek
# path and try again
##########################################################

$WimCount = 0
while ($WimCount -eq 0) {
cls
Write-Host 
Write-Host ' Enter source path. In case you are using a plugged in USB flash'
Write-Host ' drive, simply enter drive letter + colon for that drive.'
Write-Host
Write-Host ' If the source you are using is a Windows 10 ISO or DVD, enter.'
Write-Host ' path to folder where you copied ISO / DVD content.'
Write-Host 
Write-Host ' Notice please: If your source contains both 32 (x86) and 64 (x64)'
Write-Host ' bit versions, enter add \x86 or \x64 to source depending on which'
Write-Host ' bit version you want to update.'
Write-Host 
Write-Host ' Examples:'
Write-Host ' - A USB drive, enter its drive letter + : (D: or d:)'
Write-Host ' - A USB drive with both bit versions, enter D:\X86 or D:\x64'
Write-Host ' - ISO files copied to folder, enter path (F:\MyISOFiles)'
Write-Host ' - Dual bit version ISO copied to folder, enter path with bit version'
Write-Host '   (W:\ISOFolder\x86 or W:\ISOFolder)' 
Write-Host

$ISOFolder = Read-Host -Prompt ' Enter source, press Enter'
$WimFolder = $ISOFolder

    if (Test-Path $WimFolder\Sources\install.wim)
        {
        $WimCount = 1
            if (($WIMFolder -match "x86") -or ($WIMFolder -match "x64"))
            {
            $ISOFolder = $ISOFolder -replace "....$" 
            }
        }
    else
        {
        $WimCount = 0
        cls
        Write-Host
        Write-Host ' No Windows image (install.wim file) found'
        Write-Host ' Please check path and try again.'
        Write-Host
        Pause
        }
    }

$WimFile = Join-Path $WimFolder '\Sources\install.wim'

##########################################################
# List Windows editions on image, prompt user for
# edition to be be updated
##########################################################

cls
Get-WindowsImage -ImagePath $WimFile | Format-Table ImageIndex, ImageName
Write-Host 
Write-Host ' The install.wim file contains above listed Windows editions.'
Write-Host ' Which edition should be updated?'
Write-Host  
Write-Host ' Enter the ImageIndex number of correct edition and press Enter.'
Write-Host ' If this is a single edition Windows image, enter ImageIndex 1.'                                                                     
Write-Host
$Index = Read-Host -Prompt ' Select edition (ImageIndex)'
        

##########################################################
# Prompt user for folder containing downloaded WU files
# (*.cab and / or *.msu). Again, a 'while' loop is used to
# check folder contains Windows Update files, if not user
# is asked to check path and try again
##########################################################

$FileCount = 0
while ($FileCount -eq 0) {
cls
Write-Host 
Write-Host '  Enter path to folder containing downloaded Windows Update'
Write-Host '  *.cab and / or *.msu files.'
Write-Host 
Write-Host '  Be sure to enter correct path / folder!'
Write-Host                                                                       

$WUFolder = Read-Host -Prompt ' Path to folder containing downloaded Windows Update files'

$FileCount = (Get-ChildItem $WUFolder\* -Include *.msu,*.cab).Count
    if ($FileCount -eq 0)
        {
        Write-Host
        Write-Host ' No Windows Update files found in given folder.' 
        Write-Host ' Check the path and try again.'
        Write-Host
        pause
        }
    }

$WUFiles = Get-ChildItem -Path "$WUFolder" -Recurse -Include *.cab, *.msu | Sort LastWriteTime 
Write-Host
Write-Host ' Found following' $FileCount 'Windows Update files:'
Write-Host
ForEach ($File in $WUFiles)
    {Write-Host ' '$File}
Write-Host
pause    


##########################################################
# Mount Windows image in temporary mount folder.
#
# Adding eight empty lines to $EmptySpace variable to be
# used as placeholder to push output below PowerShell
# progressbar which is shown on top. Five empty lines would
# be enough for PowerShell ISE but standard PowerShell will
# need eight lines, otherwise output remains hidden
##########################################################

cls
$EmptySpace = @"



  
 



"@

Write-Host $EmptySpace
Write-Host ' Mounting Windows image. This will take a few minutes.'
Mount-WindowsImage -ImagePath $WimFolder\Sources\install.wim -Index $Index -Path $Mount | Out-Null
Write-Host
Write-Host ' Image mounted, applying updates.'
Write-Host

##########################################################
# Write updates one by one to Windows image. If OK, add
# update name including KB number to 'WUSuccess.log' file,
# if failed add to 'WUFail.log'
##########################################################

ForEach ($File in $WUFiles)
    {
    Write-Host ' Applying'$File
    Add-WindowsPackage -Path $Mount -PackagePath $File.FullName | Out-Null
    if ($? -eq $TRUE)
        {$File.Name | Out-File -FilePath C:\WUSuccess.log -Append}
     else     
        {$File.Name | Out-File -FilePath C:\WUFail.log -Append}
    }

##########################################################
# Dismount Windows image saving updated install.wim. Using
# $EmptySpace variable again to push output from under
# PowerShell progressbar to visible area under it
##########################################################

cls
Write-Host $EmptySpace
Write-Host ' Dismounting Windows image, saving updated install.wim.'
Write-Host ' This will take a minute or two.'
Dismount-WindowsImage -Path $Mount -Save | Out-Null
cls

##########################################################
# Show updates added to Windows image
##########################################################

if (Test-Path C:\WUSuccess.log)
    {
    Write-Host
    Write-Host ' Following updates successfully added to Windows image: '
    Write-Host
    $LogContent = Get-Content 'C:\WUSuccess.log'
    foreach ($Line in $LogContent)
        {Write-Host ' - '$Line}
    } 
    else
    {
    Write-Host
    Write-Host ' All updates failed, nothing added to Windows image.'
    Write-Host
    pause
    exit
    }

##########################################################
# Show failed updates
##########################################################

if (Test-Path C:\WUFail.log)
    {
    Write-Host
    Write-Host ' Following updates could not be added to Windows image: '
    $LogContent = Get-Content 'C:\WUfail.log'
    foreach ($Line in $LogContent)
        {Write-Host ' - '$Line}
    } 
    else
    {
    Write-Host
    Write-Host ' No failed updates.'}

##########################################################
# Delete temporary mount folder
##########################################################

Remove-Item $Mount

##########################################################
# Ask if user wants to create a bootable Windows USB 
# install media now, if not end the script
##########################################################

Write-Host                                                                        
Write-Host ' Windows image (install.wim) has been updated.'
Write-Host 
Write-Host ' If your source was a bootable USB drive, we are ready. It now'
Write-Host ' contains the updated install.wim file.'
Write-Host  
Write-Host ' If you started this script by copying Windows install files'
Write-Host ' from an ISO or DVD to hard disk, you can create a bootable'
Write-Host ' Windows install USB drive now to be used for installing Windows'
Write-Host ' on UEFI / GPT computers.'
Write-Host 
Write-Host '    1. Quit'
Write-Host '    2. Create USB'
Write-Host 
Write-Host 
$USB = Read-Host -Prompt ' Please enter your selection (1 or 2) and press Enter'
                                                                       
    if ($USB -eq '1')
        {
        Write-Host
        Write-Host ' The folder where you copied files from ISO now contains'
        Write-Host ' updated Windows image. You can now create a new ISO '
        Write-Host ' using the folder as source. See Part Five in this tutorial'
        Write-Host ' on TenForums to see how to do that: http://bit.ly/customiso' 
        Write-Host 
        Write-Host ' More Windows 10 tips, tricks, videos & tutorials at'
        Write-Host ' https://www.tenforums.com'
        Write-Host 
        Write-Host ' Kari "The Finn"'
        Write-Host ' - TenForums.com/members/kari.html'
        Write-Host ' - Twitter.com/KariTheFinn'
        Write-Host ' - YouTube.com/KariTheFinn'
        exit
        }
     else     
        {cls}

##########################################################
# Creating a bootable USB drive for installing Windows
# on UEFI / GPT systems
##########################################################

Write-Host
Write-Host ' Plug in a USB drive, recommended size 6 GB or more,'
Write-Host ' partitioning system is irrelevant (MBR or GPT).'
Write-Host  
Write-Host ' Notice: Remove all other USB flash drives'
Write-Host ' leaving only the one to be used connected.'
Write-Host  
Write-Host ' If more than 1 USB flash drive are connected'
Write-Host ' this process will fail.'
Write-Host  
Write-Host ' External USB hard disks may remain connected,'
Write-Host ' just remove all additional USB flash drives.'
Write-Host

pause
cls

Write-Host
Get-Disk | Format-Table Number, Friendlyname, HealthStatus, Size, PartitionStyle
Write-Host
Write-Host                                                                        
Write-Host ' Above is a list of all your connected disks.'
Write-Host 
Write-Host ' Enter the Disk Number (left  column) for USB'
Write-Host ' drive to be made as bootable Windows install'
Write-Host ' media.'
Write-Host 
Write-Host ' Be careful!'
Write-Host 
Write-Host ' Selected disk will be wiped clean and formatted.'
Write-Host ' Selecting wrong disk, you will lose any data on it.'
Write-Host ' If you are unsure, press CTRL + C to abort this script.'
Write-Host 
 
$USBNUMBER = Read-Host -Prompt ' Enter your selection, and press Enter'

cls
Write-Host                                                                        
Write-Host ' Are you sure?'
Write-Host  
Write-Host ' Selected disk will be completely wiped and formatted!'
Write-Host 
Write-Host ' Please type YES (not case sensitive) and press Enter'
Write-Host ' to confirm, any other key or string + Enter to exit.'
Write-Host
 
$AreYouSure = Read-Host -Prompt ' Type YES and press Enter to confirm'

    if ($AreYouSure -ne 'YES')
        {exit}
     else     
        {cls}

Write-Host
Write-Host ' Wiping USB flash drive clean & formatting it'

Clear-Disk -Number $USBNUMBER -RemoveData
New-Partition -DiskNumber $USBNUMBER -UseMaximumSize -AssignDriveLetter 

$USBDrive = Get-WmiObject Win32_Volume -Filter "DriveType='2'"
$USBDrive = $USBDrive.DriveLetter

Format-Volume -NewFileSystemLabel "W10 USB" -FileSystem FAT32 -DriveLetter $USBDrive.Trim(":", " ")

$USBDrive = ($USBDrive + '\')

cls

$Files = Get-ChildItem -Path $ISOFolder -Recurse
$FileCount = $Files.count
$i=0
Foreach ($File in $Files) {
    $i++
    Write-Progress -activity "Copying files to USB. Get a cup of java or shot of single malt, this will take a few minutes..." -status "$File ($i of $FileCount)" -percentcomplete (($i/$FileCount)*100)
    if ($File.psiscontainer) {$SourcefileContainer = $File.parent} else {$SourcefileContainer = $File.directory}
    $RelativePath = $SourcefileContainer.fullname.SubString($ISOFolder.length)
    Copy-Item $File.fullname ($USBDrive + $RelativePath) 
}

cls
Write-Host                                                                        
Write-Host ' Bootable Windows 10 install USB drive for UEFI / GPT'
Write-Host ' computers created.'
Write-Host   
Write-Host ' More Windows 10 tips, tricks, videos & tutorials at'
Write-Host ' https://www.tenforums.com'
Write-Host 
Write-Host ' Kari "The Finn"'
Write-Host ' - TenForums.com/members/kari.html'
Write-Host ' - Twitter.com/KariTheFinn'
Write-Host ' - YouTube.com/KariTheFinn'
Write-Host 
Write-Host 
