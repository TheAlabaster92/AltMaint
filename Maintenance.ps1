<#
    Created by Antonio Martino <TheAlabaster92>, March 16th 2017, copyright© 2017 - All rights reserved.
	Check the EULA on https://alacrisys.com/EULA for more info.
	
#>

#Preliminary Operations--------------------------------------------------------------------------------------
#Fields:
$logPath = "C:\Maint-Log\";
$logFolderExists = Test-Path $logPath
$ccleanerPath = Resolve-Path .\CCleaner\ccleaner64.exe;
$ccleanerPath = $ccleanerPath.Path;
$ausDDPath = Resolve-Path .\AusDiskDefrag\cdefrag.exe;
$ausDDPath = $ausDDPath.Path;

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
Write-Host -NoNewline "Pre-cleanup with windows clean manager...";
Start-Process cleanmgr /sagerun:1 -Wait;
Write-Host "Done.`n";

Write-Host -NoNewline "Pre-cleanup with ccleaner...";
Start-Process $ccleanerPath /Auto -Wait;
Write-Host "Done.`n";

Write-Host -NoNewline "File cleanup with windows clean manager...";
Start-Process cleanmgr /sagerun:1 -Wait;
Write-Host "Done.`n";

Write-Host -NoNewline "File cleanup with ccleaner...";
Start-Process $ccleanerPath /Auto -Wait;
Write-Host "Done.`n";


#Maintenance Queue Message-----------------------------------------------------------------------------------
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
#Write-Host -NoNewline "Running SFC /ScanNow (First Pass)...";
Write-Output "-------------------$date-------------------" >> $logPath"SFC.log";
Write-Output "First Pass:`n" >> $logPath"SFC.log";
$job = Start-Job {SFC /ScanNow} -Name "SFC 1st Pass";
Wait-Job $job;
Receive-Job $job | Out-File $logPath"SFC.log" -Append;
(Get-Content $logPath"SFC.log") -replace "\x00", "" | Set-Content $logPath"SFC.log";
(Get-Content $logPath"SFC.log") -replace "[\x08]+", "`n" | Set-Content $logPath"SFC.log";

#DISM /Online /Cleanup-Image /StartComponentCleanup----------------------------------------------------------
#Write-Host -NoNewline "Running DISM /Online /Cleanup-Image /StartComponentCleanup";
Write-Output "-------------------$date-------------------" >> $logPath"DISM.log";
Write-Output "DISM /Online /Cleanup-Image /StartComponentCleanup:`n" >> $logPath"DISM.log";
$job = Start-Job {DISM /Online /Cleanup-Image /StartComponentCleanup} -Name "Dism Component Cleanup";
Wait-Job $job;
Receive-Job $job | Out-File $logPath"DISM.log" -Append;

#DISM /Online /Cleanup-Image /RestoreHealth------------------------------------------------------------------
#Write-Host -NoNewline "Running DISM /Online /Cleanup-Image /RestoreHealth";
Write-Output "`n`nDISM /Online /Cleanup-Image /RestoreHealth:`n" >> $logPath"DISM.log";
$job = Start-Job {DISM /Online /Cleanup-Image /RestoreHealth} -Name "Dism RestoreHealth";
Wait-Job $job;
Receive-Job $job | Out-File C:\Maint-Log\DISM.log -Append;
Write-Output " " >> $logPath"DISM.log";

#SFC Second Pass---------------------------------------------------------------------------------------------
#Write-Host -NoNewline "Running SFC /ScanNow (Second Pass)...";
Write-Output "`nSecond Pass:`n" >> $logPath"SFC.log";
$job = Start-Job {SFC /ScanNow} -Name "SFC 2nd Pass";
Wait-Job $job;
Receive-Job $job | Out-File -Encoding ASCII $logPath"SFC.log" -Append;
(Get-Content $logPath"SFC.log") -replace "\x00", "" | Set-Content $logPath"SFC.log";
(Get-Content $logPath"SFC.log") -replace "[\x08]+", "`n" | Set-Content $logPath"SFC.log";

#Defrag with Windows Defrag (all drives)---------------------------------------------------------------------
#Write-Host -NoNewline "Running Defrag with Windows Defrag (all drives)...";
Write-Output "-------------------$date-------------------" >> $logPath"Windows_Defrag.log";
foreach ($drive in Get-PSDrive -PSProvider 'FileSystem') {
	Write-Output "Defrag $($drive.Name):`n" >> $logPath"Windows_Defrag.log";
    $par = "$($drive.Name):";
	$job = Start-Job {defrag $args[0]} -ArgumentList $par -Name "Windows Defrag $($drive.Name):";
	Wait-Job $job;
	Receive-Job $job | Out-File $logPath"Windows_Defrag.log" -Append;
	Write-Output " " >> $logPath"Windows_Defrag.log";
}

#Defrag with Auslogics Disk Defrag (all drives)--------------------------------------------------------------
#Write-Host -NoNewline "Running Defrag with Auslogics Disk Defrag (all drives)...";
Write-Output "-------------------$date-------------------" >> $logPath"Auslogics_Disk_Defrag.log";
$par = "-dt -o -c";
$job = Start-Job -ScriptBlock {Start-Process -FilePath $args[0] -ArgumentList $args[1] -Wait;} -ArgumentList $ausDDPath, $par -Name "Aus. DD all drives";
Wait-Job $job;
Receive-Job $job | Out-File $logPath"Auslogics_Disk_Defrag.log" -Append;
(Get-Content $logPath"Auslogics_Disk_Defrag.log") -replace "\x00", "" | Set-Content $logPath"Auslogics_Disk_Defrag.log";
(Get-Content $logPath"Auslogics_Disk_Defrag.log") -replace "[\x08]+", "`n" | Set-Content $logPath"Auslogics_Disk_Defrag.log";

#SFC Third Pass----------------------------------------------------------------------------------------------
#Write-Host -NoNewline "Running SFC /ScanNow (Third Pass)...";
Write-Output "`nThird Pass:`n" >> $logPath"SFC.log";
$job = Start-Job {SFC /ScanNow} -Name "SFC 3rd Pass";
Wait-Job $job;
Receive-Job $job | Out-File -Encoding ASCII $logPath"SFC.log" -Append;
(Get-Content $logPath"SFC.log") -replace "\x00", "" | Set-Content $logPath"SFC.log";
(Get-Content $logPath"SFC.log") -replace "[\x08]+", "`n" | Set-Content $logPath"SFC.log";
cp C:\Windows\Logs\CBS\CBS.log C:\Maint-Log\CBS-WinLog.log;

#Chkdsk (all drives)-----------------------------------------------------------------------------------------
#Write-Host -NoNewline "Chkdsk (all drives)...";
Write-Output "-------------------$date-------------------" >> $logPath"Chkdsk.log";
foreach ($drive in Get-PSDrive -PSProvider 'FileSystem') {
    $par = "$($drive.Name):";
	$job = Start-Job {chkdsk $args[0]} -ArgumentList $par -Name "Chkdsk $($drive.Name):";
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