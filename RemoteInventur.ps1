#By Fabian Keusen under  GPL-3.0 License 
#V0.2 Added more Stuff, mostly Framwork

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

Write-Host "Warning: Execution requires local admin rights on queried devices" 

$Singelconversion = -not( Test-Path HardwareInventory.csv) # If we are not Sharing a Folder with a Inventorylist we require the user to give a Indiviual Workstation
if($Singelconversion){
    $PClist = Read-Host "No HardwareInventory detected.`nEnter Target Workstation:"
}else{

}
#Import goes towards $PClist


ForEach($PC in $PClist){ #needs aproper Import here
Write-Host "$PC is the current Workstation";
$PC = [pc]::new()
$PC.Seriennummer = get-WmiObject Win32_BIOS | Select SerialNumber |%{$_.SerialNumber}
$PC.PCName = $env:computername
$PC.Username = $env:UserName

{
$Monitorsarray = Get-WmiObject -Property SerialNumberID -Namespace "root/WMI" WmiMonitorID |Select-Object  SerialNumberID | %{[char[]]($_.SerialNumberID)};

if([int]$Monitorsarray[1] -ne 0){#Removes internal and Empty Serials
$Monitorsarray[0..15]| Foreach-Object{ $PC.Monitor1 += $_;}}

if([int]$Monitorsarray[17] -ne 0){#Removes internal and Empty Serials
$Monitorsarray[16..31]| Foreach-Object{ $PC.Monitor2 += $_;}}

if([int]$Monitorsarray[33] -ne 0){#Removes internal and Empty Serials
$Monitorsarray[32..47]| Foreach-Object{ $PC.Monitor3 += $_;}}
} #Monitor Detection

{
Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\usbccgp\Enum -name [1-9]| get-member -name "?"|
    %{$_.Definition}|%{# The Prefix "string 1=" is handed over with the Same information that 
        if(($_.substring(17,4) -eq "03F0") -and ($_.substring(26,4) -ne "2B4A")){#HP but not the Keyboard
        $PC.USB += "HP:" + $_.substring(31)
        }elseif(($_.substring(17,4) -eq "046D") -and ($_.substring(26,4) -ne "C31C")){#Logitec but not the Keyboard
        $PC.USB += "Logitec:" + $_.substring(31)
        }elseif(($_.substring(17,4) -eq "1B17") -and ($_.substring(26,4) -ne "C31C")){#Plusonic that is stealing the SHENZHEN e-loam VendorID
        $PC.USB += "Plusonic:" + $_.substring(31)
        }}} #USB Detection

[void]$Ergebnis.add($PC)

}

$PC | Export-Csv -Path C:\Daten\TestOutput.csv -UseCulture -NoTypeInformation

$Ergebnis | Export-Csv -Path -UseCulture -Encoding UTF8 -NoTypeInformation

#Testing Stuff, dont carry to production:
get-WmiObject Win32_BIOS | Select SerialNumber |%{$_.SerialNumber}
get-WmiObject Win32_BIOS | Select SerialNumber |Get-ItemProperty -path "$_"

$temp = "Test" , "Killer" ,177013
ForEach($current in $temp){
Write-Host "Temp is $current"
}
