<#
    Created by Antonio Martino <TheAlabaster92>, March 16th 2017, copyright© 2017 - All rights reserved.
    check the EULA on http://thealabaster92.sharkignite-studios.com/eula/ for more info.

    Name:      Maintenance_Script;
    Date:      March 16th 2017;
    Version:   v0.2.0;
    V.Date:    July 26th 2017;

    Description:
      Automated maintenance script with log files and final loop to auto shutdown.
      This script contains some basic maintenance tasks that have to be performed every week, it allows
      for an easy set and forget maintenance.
      
      You can start this script by opening a powershell window as admin and going to the directory where this script is saved,
      then run the command .\<script name> where <script name> is the actual file name.

      Note:
        1. There's to note that this script will only use chkdsk to check the disk for errors, no fix will be performed.
           If and when a fix will be needed, chkdsk should be run manually by the user.
           Please check the logs after each maintenance to check if you need to fix errors on disk.
        2. This script makes use of third parties tools like Ccleaner and Auslogics Disk Defrag.
           Those tools should be added to the PATH environment variable before running the script, otherwise the cleanup
           and defrag tasks will be skipped.
        3. Some options have to be setup before the script is run. please refer to the documentation for cleanmgr /sageset
           and ccleaner /auto commands.
		4. Chkdsk has been updated to fetch all the drives present on the computer, it will use a Get-PSDrive to list every
		   Virtual Drive.
		   If you're unsure the drive can be checked with ChkDsk or simply don't want to scan it, remove the drive before
		   running the script.

    Changelog:
      v0.2.1: (Experimental) - Added CCleaner and Aus. Disk Defrag to script folder;
              Fixed an issue with Chkdsk and Defrag loop that wouldn't let the tools run;
              Removed old code;
	  v0.2.0: Added comments to each part of the script;
			  Added foreach loop for chkdsk to avoid entering all drives letters;
			  Added a note for ChkDsk command;
			  Removed duplicated tasks and un-necessary operations;
			  Removed Defraggler tool;
			  Changed paths to use the local variable $logPath;
			  Moved all the comments to the end of the script;
			  Increased wait time after maintenance from 5 to 15 minutes before shutting down;
			  Increased the scheduled time for shutdown from 30 to 60 seconds;
			  Fixed check for logPath existance;
			  Fixed file output;
			  Fixed console output;
      v0.1.4: Added auslogics disk defrag tool since defragging with defraggler took a lot of time;			  
              Switched from defraggler 64 to defraggler 32 bit;
              Fixed some text errors;
      v0.1.3: Fixed console output format;
      v0.1.2: Added regular expression to format the output of sfc /scannow command;
              Added copy of the advanced log files from windows for SFC and DISM;
              Added more maintenance scans;
              Added messages before the start of each procedure;
	  v0.1.1: Fixed a typo that prevented Dism tool from running;
      v0.1.0: Added final Loop to auto shutdown after 5 minutes if the user is not around;
      v0.0.7: Changed .txt files to .log files for logging purposes;
      v0.0.5: Removed echo on each line and left only the jobs output;
      v0.0.2: Fixed some issues where jobs would be skipped even if Wait-Job was issued;
      v0.0.1: First version, was a conversion from a batch script to powershell;
#>

#Preliminary Operations--------------------------------------------------------------------------------------
$logPath = "C:\Maint-Log\";
$logFolderExists = Test-Path $logPath
if ($logFolderExists -eq $false) {
  Write-Host "Log folder doesn't exists, making a new one...";
  mkdir $logPath;
  Write-Host " ";
  Write-Host  "Log folder created to"$logPath;
  Write-Host " ";
}

$msg = "Maintenance started:   ";
$date = Get-Date;
$startMsg = $msg + $date.ToString();
Write-Host $startMsg;
Write-Output "-------------------------------------" >> $logPath"MaintTime.log";
Write-Output $startMsg >> $logPath"MaintTime.log";
Write-Host " ";


#Cleanup-----------------------------------------------------------------------------------------------------
Write-Host "Pre-cleanup with windows clean manager...";
Start-Process cleanmgr /sagerun:1 -Wait;
Write-Host "Done.`n";

Write-Host "Pre-cleanup with ccleaner...";
Start-Process ccleaner64 /Auto -Wait;
Write-Host "Done.`n";

Write-Host "File cleanup with windows clean manager...";
Start-Process cleanmgr /sagerun:1 -Wait;
Write-Host "Done.`n";

Write-Host "File cleanup with ccleaner...";
Start-Process ccleaner64 /Auto -Wait;
Write-Host "Done.`n";


#Maintenance-------------------------------------------------------------------------------------------------
Write-Host "Queued jobs: 
1. SFC /ScanNow,
2. DISM /Online /Cleanup-Image /StartComponentCleanup,
3. DISM /Online /Cleanup-Image /RestoreHealth,
4. SFC /ScanNow,
5. Defrag with Windows Defrag Tool,
6. Defrag with Auslogics Disk Defrag Tool,
7. SFC /ScanNow,
8. Chkdsk.`n";
Write-Host "Please don't stop this script, when a job is completed the job will be printed on the screen and the next job will start.";
Write-Host "We're starting, please be patient...`n";


#SFC First Pass----------------------------------------------------------------------------------------------
Write-Host -NoNewline "Running SFC /ScanNow (First Pass)...";
Write-Output "-------------------$date-------------------" >> $logPath"SFC.log";
Write-Output "First Pass:`n" >> $logPath"SFC.log";
$job = Start-Job {SFC /ScanNow};
Wait-Job $job;
Receive-Job $job | Out-File $logPath"SFC.log" -Append;
(Get-Content $logPath"SFC.log") -replace "\x00", "" | Set-Content $logPath"SFC.log";
(Get-Content $logPath"SFC.log") -replace "[\x08]+", "`n" | Set-Content $logPath"SFC.log";

#DISM /Online /Cleanup-Image /StartComponentCleanup----------------------------------------------------------
Write-Host -NoNewline "Running DISM /Online /Cleanup-Image /StartComponentCleanup";
Write-Output "-------------------$date-------------------" >> $logPath"DISM.log";
Write-Output "DISM /Online /Cleanup-Image /StartComponentCleanup:`n" >> $logPath"DISM.log";
$job = Start-Job {DISM /Online /Cleanup-Image /StartComponentCleanup};
Wait-Job $job;
Receive-Job $job | Out-File $logPath"DISM.log" -Append;

#DISM /Online /Cleanup-Image /RestoreHealth------------------------------------------------------------------
Write-Host -NoNewline "Running DISM /Online /Cleanup-Image /RestoreHealth";
Write-Output "`n`nDISM /Online /Cleanup-Image /RestoreHealth:`n" >> $logPath"DISM.log";
$job = Start-Job {DISM /Online /Cleanup-Image /RestoreHealth};
Wait-Job $job;
Receive-Job $job | Out-File C:\Maint-Log\DISM.log -Append;
Write-Output " " >> $logPath"DISM.log";

#SFC Second Pass---------------------------------------------------------------------------------------------
Write-Host -NoNewline "Running SFC /ScanNow (Second Pass)...";
Write-Output "`nSecond Pass:`n" >> $logPath"SFC.log";
$job = Start-Job {SFC /ScanNow};
Wait-Job $job;
Receive-Job $job | Out-File -Encoding ASCII $logPath"SFC.log" -Append;
(Get-Content $logPath"SFC.log") -replace "\x00", "" | Set-Content $logPath"SFC.log";
(Get-Content $logPath"SFC.log") -replace "[\x08]+", "`n" | Set-Content $logPath"SFC.log";

#Defrag with Windows Defrag (all drives)---------------------------------------------------------------------
Write-Host -NoNewline "Running Defrag with Windows Defrag (all drives)...";
Write-Output "-------------------$date-------------------" >> $logPath"Windows_Defrag.log";
foreach ($drive in Get-PSDrive -PSProvider 'FileSystem') {
	Write-Output "Defrag $($drive.Name):`n" >> $logPath"Windows_Defrag.log";
    $par = "$($drive.Name):";
	$job = Start-Job {defrag $args[0]} -ArgumentList $par;
	Wait-Job $job;
	Receive-Job $job | Out-File $logPath"Windows_Defrag.log" -Append;
	Write-Output " " >> $logPath"Windows_Defrag.log";
}

#Defrag with Auslogics Disk Defrag (all drives)--------------------------------------------------------------
Write-Host -NoNewline "Running Defrag with Auslogics Disk Defrag (all drives)...";
Write-Output "-------------------$date-------------------" >> $logPath"Auslogics_Disk_Defrag.log";
$job = Start-Job {cdefrag.exe -dt -o -c};
Wait-Job $job;
Receive-Job $job | Out-File $logPath"Auslogics_Disk_Defrag.log" -Append;
(Get-Content $logPath"Auslogics_Disk_Defrag.log") -replace "[\x08]+", "`n" | Set-Content $logPath"Auslogics_Disk_Defrag.log";

#SFC Third Pass----------------------------------------------------------------------------------------------
Write-Host -NoNewline "Running SFC /ScanNow (Third Pass)...";
Write-Output "`nThird Pass:`n" >> $logPath"SFC.log";
$job = Start-Job {SFC /ScanNow};
Wait-Job $job;
Receive-Job $job | Out-File -Encoding ASCII $logPath"SFC.log" -Append;
(Get-Content $logPath"SFC.log") -replace "\x00", "" | Set-Content $logPath"SFC.log";
(Get-Content $logPath"SFC.log") -replace "[\x08]+", "`n" | Set-Content $logPath"SFC.log";
cp C:\Windows\Logs\CBS\CBS.log C:\Maint-Log\CBS-WinLog.log;

#Chkdsk (all drives)-----------------------------------------------------------------------------------------
Write-Host -NoNewline "Chkdsk (all drives)...";
Write-Output "-------------------$date-------------------" >> $logPath"Chkdsk.log";
foreach ($drive in Get-PSDrive -PSProvider 'FileSystem') {
    $par = "$($drive.Name):";
	$job = Start-Job {chkdsk $args[0]} -ArgumentList $par;
	Wait-Job $job;
	Receive-Job $job | Out-File $logPath"Chkdsk.log" -Append;
	Write-Output " " >> $logPath"Chkdsk.log";
}

#End Message-------------------------------------------------------------------------------------------------
$msg = "Maintenance completed: ";
$date = Get-Date;
$endMsg = $msg + $date.ToString();
Write-Host $endMsg;
Write-Output $endMsg >> $logPath"MaintTime.log";


#Shutdown Loop-----------------------------------------------------------------------------------------------
$TimeStart = Get-Date;
$TimeEnd = $timeStart.addminutes(15);
Write-Host "Start Time: $TimeStart";
Write-Host "End Time:   $TimeEnd";
Write-Host "The computer will shutdown by itself when end time is reached, if you want to avoid it, press ctrl+c before end time.";
Do { 
 $TimeNow = Get-Date;
 if ($TimeNow -ge $TimeEnd) {
  Write-host "Shutdown planned, the computer will shutdown in 30 seconds.";
  shutdown -s -t 60;
 } else {
  Write-Host "it's $TimeNow, press ctrl+c before $TimeEnd to abort shutdown...";
 }
 Start-Sleep -Seconds 60;
}
Until ($TimeNow -ge $TimeEnd)