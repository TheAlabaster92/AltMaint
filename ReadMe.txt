Project Info:

Name            AltMaint
Extended Name   Alternative windows maintenance
Version         v0.2.3.20170808.1704
Author          TheAlabaster92
Copyright       Created by Antonio Martino <TheAlabaster92>, March 16th 2017, copyright© 2017 - All rights reserved.
EULA            https://alacrisys.com/EULA


Contact Info:

Website:        https://alacrisys.com
Contacts:       thealabaster92@hotmail.com


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
	3. Some options have to be setup before the script is run. please refer to the documentation for cleanmgr /sageset
	   and ccleaner /auto commands.
	4. Chkdsk has been updated to fetch all the drives present on the computer, it will use a Get-PSDrive to list every
	   Virtual Drive.
	   If you're unsure the drive can be checked with ChkDsk or simply don't want to scan it, remove the drive before
	   running the script.