#By Fabian Keusen under  GPL-3.0 License 

class pc{#What we take from Each user
        [String]$Seriennummer
        [String]$PCName
        [String]$Username
        [String]$Monitor1
        [String]$Monitor2
        [String]$Monitor3
        [String]$USB
}

<#
$verschiedenePCNamen = "PLD50WBA8..",""

ForEach($PC in $verschiedenePCNamen){
    $AktuellerPC = [pc]::new()
    $AktuellerPC.seriennummer = ""
    $AktuellerPC.PCN = ""
    [void]$Ergebnis.add($AktuellerPC)
}
#>

#Import goes towards $PClist
$Monitorsarray = Get-WmiObject -Property SerialNumberID -Namespace "root/WMI" WmiMonitorID |Select-Object  SerialNumberID | %{[char[]]($_.SerialNumberID)};

if([int]$Monitorsarray[1] -ne 0){
$Monitorsarray[0..15]| Foreach-Object{ $PC.Monitor1 += $_;}}

if([int]$Monitorsarray[17] -ne 0){
$Monitorsarray[16..31]| Foreach-Object{ $PC.Monitor2 += $_;}}

if([int]$Monitorsarray[33] -ne 0){
$Monitorsarray[32..47]| Foreach-Object{ $PC.Monitor3 += $_;}}

Write-Host "$amount"
Write-Host "$Monitors"

$currentmonitoramount = ($currentmonitorsntemp.SerialNumberID.count /16);


ForEach($PC in $PClist){ #needs aproper sting here
Write-Host "$PC is the current Workstation";
$PC = [pc]::new()
$PC.Seriennummer = get-WmiObject Win32_BIOS | Select SerialNumber |%{$_.SerialNumber}
$PC.PCName = $env:computername
$PC.Username = $env:UserName

$PC
}


$PC | Export-Csv -Path C:\Daten\TestOutput.csv -UseCulture -NoTypeInformation

$Ergebnis | Export-Csv -Path -UseCulture -Encoding UTF8 -NoTypeInformation

#Test:
get-WmiObject Win32_BIOS | Select SerialNumber |%{$_.SerialNumber}
get-WmiObject Win32_BIOS | Select SerialNumber |Get-ItemProperty -path "$_"

$temp = "Test" , "Killer" ,177013
ForEach($current in $temp){
Write-Host "Temp is $current"
}

Get-WmiObject -Property SerialNumberID -Namespace "root/WMI" WmiMonitorID |
                Select-Object SerialNumberID |