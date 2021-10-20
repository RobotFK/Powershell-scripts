#By Fabian Keusen under  GPL-3.0 License 
#V0.2 Added more Stuff, mostly Framwork
#V0.3 Replaced Registry readout with wmi options
#V0.4 Replaced all Wmi with Cmi, added a system to detect cmi internal errors
#v0.5 Fixed Exeption detection and added a system to stop Overriding of output
#v1.0 Firs release.It might have bugs to fix and edge cases

#Start-Transcript -Path "P:\Programming\transcript.txt"

class pc{#What we take from Each user
        [String]$Seriennummer
        [String]$PCName
        [String]$Username
        [String]$Monitor1
        [String]$Monitor2
        [String]$Monitor3
        [String]$USB
}

$Ergebnis = @();
$count = 0;

Write-Host "Warning: Execution requires local admin rights on queried devices" 

$Singelconversion = -not( Test-Path HardwareInventory.csv) # If we are not Sharing a Folder with a Inventorylist we require the user to give a Indiviual Workstation
if($Singelconversion){
    $PClist = Read-Host "No HardwareInventory detected.`nEnter Target Workstation:"
}else{
    Write-Host "HardwareInventory.csv file found, importing list"
    $PClist = Get-Content -Path .\HardwareInventory.csv -Filter PLD*|Select |%{if(($_ -notmatch "Computer") -and ($_ -like "*,*")){($_ -split ",")[0]}}
}

$sw = [Diagnostics.Stopwatch]::StartNew()
$Error.clear() 
ForEach($PCName in $PClist){
$Exeption = $False;#Reset just to make sure
$count += 1;
$progress = [math]::Round(($count/$PClist.count),4)
$PClistcount = $PClist.count
Write-Progress -Activity "Progress of Checking $PClistcount Entries" -Status "$progress% Complete:" -PercentComplete $progress 

if (-not(Test-Connection -ComputerName $PCName -Count 1 -Quiet)){ #Ensure the PC is online
$PC = [pc]::new()
$PC.PCName = $PCName ;
$PC.Username = "Offline";
$Ergebnis += ($PC);
$Exeption = $true;#This is a specal case and should not Recieve Standard Procedure
"$PCName Offline"
}elseif((Test-Connection -Computername $PCName -Count 1).IPV6Address -eq $null){#Catches ones with a Pingresponse but not on the Network anymore
$PC = [pc]::new()
$PC.PCName = $PCName ;
$PC.Username = "Not on the Network";
$Ergebnis += ($PC);
$Exeption = $true;#This is a specal case and should not Recieve Standard Procedure
"$PCName not on the Network"
}

#Catch If we cant access Some Cim stuff
if(-not($Exeption)){
try{
$null = Get-CimInstance -ClassName WMIMonitorID -ComputerName $PCName -Namespace root\wmi -ErrorAction:SilentlyContinue
}
Finally{
    if($Error -ne $null){"Cim Acces Restrictions for $PCName"
    $Error.clear()
    $PC = [pc]::new()
    $PC.PCName = $PCName ;
    $PC.Username = "Cim Error";
    $Ergebnis += ($PC);
    $Exeption = $true;#This is a specal case and should not Recieve Standard Procedure
    }
}}

if (-not($Exeption)){
$PC = [pc]::new()
$PC.PCName = $PCName ;
$PC.Seriennummer = get-CimInstance Win32_BIOS -ComputerName $PC.PCName| Select SerialNumber |%{$_.SerialNumber}
$PC.Username = Get-CimInstance -Class win32_computersystem -ComputerName $PCName | select username |%{($_.username.split("\\"))[1]}

#Monitor Detection:

$Monitorsarray = Get-CimInstance -Property SerialNumberID -ComputerName $PC.PCName -Namespace "root/WMI" WmiMonitorID |Select-Object  SerialNumberID | %{[char[]]($_.SerialNumberID)};

if([int]$Monitorsarray[1] -ne 0){#Removes internal and Empty Serials
$Monitorsarray[0..15]| Foreach-Object{ $PC.Monitor1 += $_;}}

if([int]$Monitorsarray[17] -ne 0){#Removes internal and Empty Serials
$Monitorsarray[16..31]| Foreach-Object{ $PC.Monitor2 += $_;}}

if([int]$Monitorsarray[33] -ne 0){#Removes internal and Empty Serials
$Monitorsarray[32..47]| Foreach-Object{ $PC.Monitor3 += $_;}}


#USB Detection
Get-CimInstance -ComputerName $PCName -Class Win32_USBDevice | select DeviceID |%{$_.DeviceID}|%{
        if(($_.substring(8,4) -eq "03F0") -and ($_.substring(17,4) -ne "2B4A") -and ($_.substring(17,4) -ne "154A")){#HP but not the Keyboard or Mouse
        $PC.USB += "HP:" + ($_ -split "\\")[2]
        }elseif(($_.substring(8,4) -eq "046D") -and ($_.substring(17,4) -ne "C31C")){#Logitec but not the Keyboard
        $PC.USB += "Logitec:" + ($_ -split "\\")[2]
        }elseif(($_.substring(8,4) -eq "1B17")){#Plusonic that is stealing the SHENZHEN e-loam VendorID
        $PC.USB += "Plusonic:" + ($_ -split "\\")[2]
        }} 

#Adding Object to array
"$PCName Added"
$Ergebnis += ($PC);


}} #End of main loop

if(-not(Test-Path -LiteralPath C:\Daten\TestOutput.csv)){
$Ergebnis | Export-Csv -Path C:\Daten\TestOutput.csv -UseCulture -Encoding UTF8 -NoTypeInformation
}else{
Write-Host "File already Detected,exporting additonally with Unix-seconds in Name";
$time = (Get-Date -UFormat "%s").split(",")[0];
$Ergebnis | Export-Csv -Path C:\Daten\"$time-"TestOutput.csv -UseCulture -Encoding UTF8 -NoTypeInformation
}
Write-Host "Succesfull Execution";
$sw.Stop()
Write-Host "Time Passed:";
$sw.Elapsed
Read-Host -Prompt "Press Enter to exit"
