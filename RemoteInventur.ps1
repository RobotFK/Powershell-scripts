#By Fabian Keusen under  GPL-3.0 License 
#V0.2 Added more Stuff, mostly Framwork
#V0.3 Replaced Registry readout with wmi options
#V0.4 Replaced all Wmi with Cmi, added a system to detect cmi internal errors
#v0.5 Fixed Exeption detection and added a system to stop Overriding of output
#v1.0 First release.It might have bugs to fix and edge cases
#v1.1 Added User input befor and after the Main loop
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

$Ergebnis = @();#Storing of Results until they are exported
$count = 0; #Used for Showing Progress

Write-Host "Warning: Execution requires local admin rights on queried devices"

$prep =$False
while(-not($prep)){ #We repeat until we get an Input
$Inputmethod = Read-Host "Select Input method:`n(1) Manual Entry`n(2) Cmac list`n(3) Selective Cmac list `n(4) Update Remoteinventory list `nSelection"
Switch ($Inputmethod){
    1{$PClist = Read-Host "Enter Target Workstation:"
      $prep = $True
      }
    2{
        if( Test-Path HardwareInventory.csv){
            $PClist = Get-Content -Path .\HardwareInventory.csv -Filter PLD*|Select |
                %{if(($_ -notmatch "Computer") -and ($_ -like "*,*")){($_ -split ",")[0]}}
                $prep = $True
        }else{Write-Host "HardwareInventory.csv not In Parentfolder detected"}}
    3{
        if( Test-Path HardwareInventory.csv){
            $PClist = Get-Content -Path .\HardwareInventory.csv -Filter PLD*|Select |
                %{if(($_ -notmatch "Computer") -and ($_ -like "*,*")){($_ -split ",")[0]}}
            $Filter = Read-Host "Enter Workstation Filter (* ist the Wildcard)"
            [array] $PClist = $PClist | Where-Object { $_ -like $Filter}
            Write-Host $PClist.count "Entries Selected"
            $prep = $True
        }else{Write-Host "HardwareInventory.csv not In Parentfolder detected"}}
    4{#Extract Pclist form the file
        if( Test-Path RemoteinventoryOutput.csv){
        	$Old = Import-Csv -Path .\RemoteinventoryOutput.csv -UseCulture -Encoding UTF8
            $PClist = $null #Just to be sure
            $PClist += $Old| Where {($_.Username -eq "Offline") -or ($_.Username -eq "Cim Error")}|%{$_.PCName}
            Write-Host $PClist.Count "Entries Selected"
            $prep = $True
    }else{"List not found"}}
}
if(-not($prep)){
    Read-Host -Prompt "Preperation incomplete.Enter to Restart"
    cls
}}
if($Inputmethod -ne "1"){
if((Read-Host "Aren you sure(this might take a while)? y/n") -eq "n"){
Write-Host "Aborting"
Start-Sleep -Milliseconds 1000
exit
}else{"Use Controll + C to abort later if need be"}}

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
}
#Catch If we cant access Some Cim stuff
if(-not($Exeption)){
try{
$null =Get-CimInstance -Property SerialNumberID -ComputerName $PCName -Namespace "root/WMI" WmiMonitorID -ErrorAction:SilentlyContinue
}
Finally{
    if($Error -ne $null){"Remote acces Restrictions for $PCName"
    $Error.clear()
    $PC = [pc]::new()
    $PC.PCName = $PCName ;
    $PC.Username = "Remote Error";
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
        }elseif(($_.substring(8,4) -eq "046D") -and ($_.substring(17,4) -ne "C31C")){#Logitec but not the Standard Keyboard
            if((($_.split("\\"))[2])[1] -ne "&"){ #If the Second Character after In the Value is "&" the SN is not usefull
                $PC.USB += "Logitec:" + ($_ -split "\\")[2]}
        }elseif(($_.substring(8,4) -eq "1B17")){#Plusonic that is stealing the SHENZHEN e-loam VendorID
            if((($_.split("\\"))[2])[1] -ne "&"){ #See above
                $PC.USB += "Plusonic:" + ($_ -split "\\")[2]}
        }} 

#Adding Object to array
"$PCName Added"
$Ergebnis += ($PC);


}} #End of main loop


if(-not(Test-Path -LiteralPath .\RemoteinventoryOutput.csv)){
Write-Host "Currently no File detcted in Parent folder , Creating new File Here"
$Ergebnis | Export-Csv -Path .\RemoteinventoryOutput.csv -UseCulture -Encoding UTF8 -NoTypeInformation
}else{
    if($Inputmethod -ne  "4"){
    $Outputtyp = Read-Host "File already Detected,select output method:`n(1) New File`n(2) Fill in File `n(3)Update File `n";
    }else{
    $Outputtyp = Read-Host "File already Detected,select output method:`n(1) Seperate File`n(2) Fill in File `n(3)Update File `n";
    }
    Switch ($Outputtyp){
        1{$Ergebnis | Export-Csv -Path C:\Daten\"$time-"RemoteinventoryOutput.csv -UseCulture -Encoding UTF8 -NoTypeInformation}
        2{#Double For loop might seem bad,but Read/write is fairly fast now (and this is the best thing i can think of)
            $Ergebnis|Where{-not(($_.Username -eq "Offline") -or ($_.Username -eq "Cim Error"))}|Where{$old -contains $_.PCName}%{ $_.PcName}
            $temp = $_
                        
            
                            #Do stuff
                    
            }
        #$Old| Where {($_.Username -eq "Offline") -or ($_.Username -eq "Cim Error")}|%{#if(($Ergebnis.Pcname -contains $_)
        #$_.PCName
        3{"Not Implemented yet"}



    }

$time = (Get-Date -UFormat "%s").split(",")[0];
$Ergebnis | Export-Csv -Path C:\Daten\"$time-"TestOutput.csv -UseCulture -Encoding UTF8 -NoTypeInformation
}
Write-Host "Succesfull Execution";
$sw.Stop()
Write-Host "Time Passed:";
Write-Host "Hours: "$sw.Elapsed.Hours "`nMinutes: "$sw.Elapsed.Minutes "`nSeconds: " $sw.Elapsed.Seconds
Read-Host -Prompt "Press Enter to exit"
