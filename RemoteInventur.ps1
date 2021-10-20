#By Fabian Keusen under  GPL-3.0 License 
#V0.2 Added more Stuff, mostly Framwork
#V0.3 Replaced Registry readout with wmi options
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
<#
$verschiedenePCNamen = "PLD50WBA8..",""

ForEach($PC in $verschiedenePCNamen){
    $AktuellerPC = [pc]::new()
    $AktuellerPC.seriennummer = ""
    $AktuellerPC.PCN = ""
    [void]$Ergebnis.add($AktuellerPC)
}
#>

Write-Host "Warning: Execution requires local admin rights on queried devices" 

$Singelconversion = -not( Test-Path HardwareInventory.csv) # If we are not Sharing a Folder with a Inventorylist we require the user to give a Indiviual Workstation
if($Singelconversion){
    $PClist = Read-Host "No HardwareInventory detected.`nEnter Target Workstation:"
}else{
    Write-Host "HardwareInventory.csv file found, importing list"
    $PClist = Get-Content -Path .\HardwareInventory.csv -Filter PLD*|Select |%{if(($_ -notmatch "Computer") -and ($_ -like "*,*")){($_ -split ",")[0]}}
}

$Error.clear() 
ForEach($PCName in $PClist){
$count += 1;
$progress = [math]::Round(($count/$PClist.count),4)
$PClistcount = $PClist.count
Write-Progress -Activity "Total Progress" -Status "$progress% Complete:" -PercentComplete $progress -id "$PClistcount Entries"

if (Test-Connection -ComputerName $PCName -Count 1 -Quiet -TimeoutSeconds 1){ #Ensure the PC is online
$PC = [pc]::new()
$PC.PCName = $PCName ;
$PC.Username = "Offline";
$Ergebnis += ($PC);
continue;
}

#Catch If we cant acces Some stuff
try{
$null = Get-CimInstance -ClassName WMIMonitorID -ComputerName $PCName -Namespace root\wmi -ErrorAction:SilentlyContinue
#$null = Get-CimInstance -Class Win32_USBDevice -ComputerName $PCName -ErrorAction:SilentlyContinue
}
Finally{
    if($Error -ne $null){"Cim Acces Restrictions"
    $Error.clear()}
}

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
$Ergebnis += ($PC);


} #End of main loop

$Ergebnis | Export-Csv -Path C:\Daten\TestOutput.csv -UseCulture -Encoding UTF8 -NoTypeInformation

#Testing Stuff, dont carry to production:
<#
get-WmiObject Win32_BIOS | Select SerialNumber |%{$_.SerialNumber}
get-WmiObject Win32_BIOS | Select SerialNumber |Get-ItemProperty -path "$_"

$temp = "Test" , "Killer" ,177013
ForEach($current in $temp){
Write-Host "Temp is $current"
}

Workflow Massping{
    ForEach -Parallel ($PCName in $PClist){ #needs aproper Import here
        if (Test-Connection -ComputerName $PCName -Count 1 -Quiet){"$PCName is online"}else{"Offline"}"Ran $PCName"}
} Massping

Invoke-Command -ComputerName PLD104DAU094Y -{
Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\usbccgp\Enum -name [1-9]| get-member -name "?"|%{$_.Definition}}

sc \\computer_name start remoteregistry
$test = REG QUERY \\PLD104DAU094Y\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\usbccgp\Enum;$test

gwmi -Class Win32_USBDevice | select DeviceID 

Get-WmiObject -Class win32_computersystem -ComputerName $PCName | select username |%{($_.username.split("\\"))[1]} 

$PClist = "PLD104DAU091Y","PLD104DAU092Y","PLD104DAU093Y","PLD104DAU094Y"
$count = 0;
ForEach($PCName in $PClist){
$count += 1;
$progress = ($count/$PClist.count)
Write-Progress -Activity "Total Progress" -Status "$progress% Complete:" -PercentComplete $progress
$temp = $PClist.count
Write-Host "$progress is $count by $temp "

if((Get-WmiObject -ComputerName P103DIS2OG -Namespace root/CIMV2 __Namespace |Select Name |%{$_.name}) -contains "WmiMonitorID")

P103DIS2OG

}

WmiMonitorID
Get-WmiObject -computername P103DIS2OG -Namespace root\wmi -list |%{if($_.name -like "Wmi*"){$_}}
Get-WmiObject -Namespace root\wmi -list |%{$_.name}|%{if($_ -like "Wmi*"){$_}}

$cred = get-credential
Get-WmiObject  -credential $cred -Class WmiMonitorID -ComputerName P103DIS2OG -Namespace root\wmi|%{$_.properties}|%{if($_.name -like "Serial*"){$_.value}}

#This needs to work without list
Get-WmiObject -Class WmiMonitorID -ComputerName P103DIS2OG -List -Namespace root\wmi|%{$_.properties}|%{if($_.name -like "Serial*"){$_}}

Get-WmiObject -computername P103DIS2OG -Namespace root\wmi -list

Get-DCOMSecurity -ComputerName P103DIS2OG|%{if($_.name -ne ""){$_.name}}

Get-CimInstance -ComputerName $PCName -Class Win32_USBDevice | select DeviceID |%{$_.DeviceID}#>

#Works
Get-CimClass -ClassName WMIMonitorID -ComputerName P103DIS2OG -Namespace root\wmi

#Does not work
Get-CimInstance -ClassName WMIMonitorID -ComputerName P103DIS2OG -Namespace root\wmi 
Get-WmiObject -ClassName WMIMonitorID -ComputerName P103DIS2OG -Namespace root\wmi 

$Error.clear()
try{Get-WmiObject -ClassName WMIMonitorID -ComputerName P103DIS2OG -Namespace root\wmi}
Finally{
    if($Error -ne $null){"Error Found"}
}

$Error.clear()

try{$null = Get-CimInstance -ClassName WMIMonitorID -ComputerName P103DIS2OG -Namespace root\wmi -ErrorAction:SilentlyContinue}
Finally{
    if($Error -ne $null){"Cim Acces Restrictions"
    $Error.clear()}
}

$PCName = "PLD104DAU094Y"
Test-Connection -ComputerName $PCName -Count 1 -Quiet -Delay 0
