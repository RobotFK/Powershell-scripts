###Changelog########################################################################################
#By Fabian Keusen under  GPL-3.0 License 
#V0.2 Added more Stuff, mostly Framwork
#V0.3 Replaced Registry readout with wmi options
#V0.4 Replaced all Wmi with Cmi, added a system to detect cmi internal errors
#v0.5 Fixed Exeption detection and added a system to stop Overriding of output
#v1.0 First release.It might have bugs to fix and edge cases
#v1.1 Added User input befor and after the Main loop
#v1.1 Made Updating a reality
#v1.1.2 Filepath Hotfix 
#(Yeah, this means that every version has an added .0 at the end unless Specified)
#v1.2 Improving Readability
#v1.3 Bugfixes in Monitorreadout,Filereadout and Test-Connection handeling
#v1.4 Removing WIP Mass-ping, added Userguide
####################################################################################################

#Start-Transcript -Path "P:\Programming\transcript.txt"

###User-Guide#######################################################################################
#
#Preparation:
#Place this Script in a Folder
#-This is a Requirement
#
#Place a File with a list of Computernames in the same Folder
#-This is optional,but make life much easier
#-The File needs to be called HardwareInventory.csv
#-Lines with Computer in them are Ignored
#-Valid lines in the File are either Only the Computername or the Computername being the First entry and seperated form the rest of the File by a comma
#
#Place a File of a Pervious RemoteInvetur (RemoteinventoryOutput.csv) in the same Folder
#-This is optional,but allows updating this list, saving Time and Comuting/Networkpower 
#
#Input method Explainations
#Manual Entry: (1)
#Runs the Script for only a single Computer
#Cmac list: (2)
#Imports a list from a File and Runs through every entry
#Selective Cmac list:(3)
#Imports a list from a File and Runs through entries,filtering by a afterwards entered Filter
#Update Remoteinventory list: (4)
#Imports a list from a File and Runs through entries marked with error or offline
#
#During the Main Process progress will be displayed
#
#Output method Explainations
#New File:(1)
#Takes the Gathered information into a New file,overriding if a File already exist in the folder
#Fill in File: (2)
#Replaces all Entries that were marked with error or offline and that have new information.New entries or differing information on valid entries are discarded

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
[int]$count = 0; #Used for Showing Progress

Write-Host "Warning: Execution requires local admin rights on queried devices"

[bool]$prep =$False
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
            $Filter = Read-Host "Enter Full Workstation Filter (* ist the Wildcard)"
            [array] $PClist = $PClist | Where-Object { $_ -like $Filter}
            Write-Host $PClist.count "Entries Selected"
            $prep = $True
        }else{Write-Host "HardwareInventory.csv not In Parentfolder detected"}}
    4{#Extract Pclist form the file
        if( Test-Path RemoteinventoryOutput.csv){
        	$Old = Import-Csv -Path .\RemoteinventoryOutput.csv -UseCulture -Encoding UTF8
            $PClist = $null #Just to be sure
            $PClist += $Old| Where {($_.Username -eq "Offline") -or ($_.Username -like "*Error*")}|%{$_.PCName}
            Write-Host $PClist.Count "Entries Selected"
            $prep = $True
    }else{"List not found"}}
}
    if(-not($prep)){
        Read-Host -Prompt "Preperation incomplete.Restart by Pressing Enter"
        cls
    }elseif(($Inputmethod -ne "1") -and (Read-Host "$($PClist.count) Entries will be Testesd `nAre you sure(this might take a while)? y/n") -eq "n"){
        Read-Host -Prompt "Restart Selection by Pressing Enter"
        $prep = $False;
        cls
    }else{"Use Controll + C to abort, if need be"}
}

$sw = [Diagnostics.Stopwatch]::StartNew()
$Error.clear() 

ForEach($PCName in $PClist){
$Exeption = $False;#Reset just to make sure

#Progressblock
$count += 1;
$progress = [math]::Round(($count/$PClist.count),4)*100
Write-Progress -Activity "Progress of Checking $($PClist.count) Entries" -Status "$progress% Complete:" -PercentComplete $progress 
#End of Progressblock

if (-not(Test-Connection -ComputerName $PCName -Count 1 -Quiet)){ #Ensure the PC is online
$PC = [pc]::new()
$PC.PCName = $PCName ;
$PC.Username = "Offline";
$Ergebnis += ($PC);
$Exeption = $true;#This is a specal case and should not Recieve Standard Procedure
"$PCName Offline"
}

#Catch Errors
if(-not($Exeption)){
try{
$Error.clear()
$null = Get-CimInstance Win32_BIOS -ComputerName $PCName -ErrorAction:SilentlyContinue
$null = Get-CimInstance -Class win32_computersystem -ComputerName $PCName -ErrorAction:SilentlyContinue
$null = Get-CimInstance -Property SerialNumberID -ComputerName $PCName -Namespace "root/WMI" WmiMonitorID -ErrorAction:SilentlyContinue
}
Finally{
if($Error -ne $null){
    "Error Found, $PCName caused"
    Foreach($Err in $Error){
        $Errname =$err.exception.gettype().Name
        if($Errorlist -notcontains $Errname){
            $Errorlist +=$Errname;
        }
    }
    $Error.clear()
    $PC = [pc]::new()
    $PC.PCName = $PCName ;
    $PC.Username = "Error";
    $Ergebnis += ($PC);
    $Exeption = $true;#This means that this is a specal case and should not Recieve Standard Procedure
    $Errorlist
    Clear-Variable -name Errorlist
}}}

if (-not($Exeption)){
$PC = [pc]::new()
$PC.PCName = $PCName ;
$PC.Seriennummer = get-CimInstance Win32_BIOS -ComputerName $PC.PCName| Select SerialNumber |%{$_.SerialNumber}
$PC.Username = Get-CimInstance -Class win32_computersystem -ComputerName $PCName | select username |%{
    if($_.username -ne $null){
        ($_.username.split("\\"))[1]
    }else{"Null"}
    }

#Monitor Detection:

$Monitorsarray = Get-CimInstance -Property SerialNumberID -ComputerName $PC.PCName -Namespace "root/WMI" WmiMonitorID |%{[char[]]($_.SerialNumberID)};

if([int]$Monitorsarray[1] -ne [char]0){#Removes internal and Empty Serials
$Monitorsarray[0..15]| Foreach-Object{ $PC.Monitor1 += $_;}}

if([int]$Monitorsarray[17] -ne [char]0){#Removes internal and Empty Serials
$Monitorsarray[16..31]| Foreach-Object{ $PC.Monitor2 += $_;}}

if([int]$Monitorsarray[33] -ne [char]0){#Removes internal and Empty Serials
$Monitorsarray[32..47]| Foreach-Object{ $PC.Monitor3 += $_;}}


#USB Detection
Get-CimInstance -ComputerName $PCName -Class Win32_USBDevice |%{$_.DeviceID}|%{
        if(($_.substring(8,4) -eq "03F0") -and ($_.substring(17,4) -ne "2B4A") -and ($_.substring(17,4) -ne "154A")){#HP but not the Keyboard or Mouse
            if((($_.split("\\"))[2])[1] -ne "&"){
                $PC.USB += "HP:" + ($_ -split "\\")[2]}
        }elseif(($_.substring(8,4) -eq "046D") -and ($_.substring(17,4) -ne "C31C")){#Logitec but not the Standard Keyboard
            if((($_.split("\\"))[2])[1] -ne "&"){ #If the Second Character after In the Value is "&" the SN is not usefull
                $PC.USB += "Logitec:" + ($_ -split "\\")[2]}
        }elseif(($_.substring(8,4) -eq "1B17")){#Plusonic that is stealing the SHENZHEN e-loam VendorID
            if((($_.split("\\"))[2])[1] -ne "&"){ #See above
                $PC.USB += "Plusonic:" + ($_ -split "\\")[2]}
        }
       } 

#Adding Object to array
"$PCName Added"
$Ergebnis += ($PC);


}} #End of main loop


if(-not(Test-Path -LiteralPath .\RemoteinventoryOutput.csv)){
Write-Host "Currently no File detcted in Parent folder , Creating new File Here"
$Ergebnis | Export-Csv -Path .\RemoteinventoryOutput.csv -UseCulture -Encoding UTF8 -NoTypeInformation
}else{
    Write-Host "File already Detected,select output method:"
    if($Inputmethod -ne  "4"){
    $Outputtype = Read-Host "(1) New File`n(2) Fill in File `n";
    }else{
    $Outputtype = Read-Host "(1) Seperate File`n(2) Update incomplete parts of the File `n";
    }
    "Writing,don't Panic"
    Switch ($Outputtype){
        1{$Ergebnis | Export-Csv -Path .\RemoteinventoryOutput.csv -UseCulture -Encoding UTF8 -NoTypeInformation}
        2{#Double For loop might seem bad,but Read/write is fairly fast now (and this is the best thing i can think of)
            $changes = 0
            For($Ergebnislocation = 0;$Ergebnislocation -le ($old.count)-1;$Ergebnislocation++){
                $Ergebnis|Where{-not(($_.Username -eq "Offline") -or ($_.Username -like "*Error*") -or ($_.Username -like "Null"))}|%{if($old[$Ergebnislocation].PCname -eq $_.PCname){
                    $old[$Ergebnislocation] = $_;
                    $changes++
                    #Write-Host $old[$Ergebnislocation].PCname " ($Ergebnislocation) has been updated"; # If you need to know what has been killed
                    }}

            }
            Write-Host "$changes Entries changed"
            $old | Export-Csv -Path .\RemoteinventoryOutput.csv -UseCulture -Encoding UTF8 -NoTypeInformation}#Old now contains all of the Updates and just overrides
          }
          }

Write-Host "Succesfull Execution";
$sw.Stop()
Write-Host "Time Passed:";
if ($sw.Elapsed.Hours -ne 0){
    Write-Host "Hours: "$sw.Elapsed.Hours
} 
Write-Host "Minutes:" $sw.Elapsed.Minutes 
Write-Host "Seconds: " $sw.Elapsed.Seconds
Read-Host -Prompt "Press Enter to exit"

#Continue working on this
