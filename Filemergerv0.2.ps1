#by Fabian Keusen under GNU General Public License
#v0.1 Inital Work (Framework and Handle-Time)
#v0.2 Added license and Funtion 2-7

<#Todo: 
Function 8
Fix No Shitty sn
#>
#This  $([char]30) Ascii character is designed for this delimiting Rows
$dataarray  = @(); #Used for convertion
$files = 0; #Amount of Files to process
$global:arrayline ;#Current line we are reading out (This need acess so we can skip on multiline readouts)
$global:Currentrow = "Time,PC-Name,Username,PC-SN,∃(USB),∃(Monitors),∃(PastMonitors)," #This will be how the data is stored each line,this one is also the top line
$global:Stage = 0; # In witch part of the Possible 8 we are currently writing
$output = @(); # Finall output we fill each Element with a line;
$output += $Currentrow;

function Handle-Time {
    param(
    [Parameter()]
	[string] $unixtime
    )
    #$unixtime = "1633679665,40686"

    $time = $null #stops stuff from leaking
    $unixtime.split(",")|foreach { #Rounds down to last Second (Adding seconds doesnt work otherwise)
    if($time -eq $null){
    $time = $_;
    }} 
    $Humantime =(Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($time))
    $Humantime = $Humantime.ToString("MM/dd/yyyy HH:mm")
    Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$Humantime + ","); #Long but allows us that change variables outside the Functions scope

    Set-Variable -Name Stage -Scope global -Value 2; #Only 1 datapoint, always move to next Stage
    #Write-Host "Timeaddition sucsess"
}

function Handle-PCName { #Trivial here but makes code more clear and readable
    param(
    [Parameter()]
	[string] $PCName
    )
    Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$PCName + ",");
    #$currentrow

    Set-Variable -Name Stage -Scope global -Value 3;#Only 1 datapoint, always move to next Stage
}

function Handle-User { #Trivial here but makes code more clear and readable
    param(
    [Parameter()]
	[string] $Username
    )
    Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$Username + ",");

    Set-Variable -Name Stage -Scope global -Value 4;#Only 1 datapoint, always move to next Stage
}

function Handle-PCSN { #Trivial here but makes code more clear and readable
    param(
    [Parameter()]
	[string] $PCSN
    )
    Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$PCSN + ",");

    Set-Variable -Name Stage -Scope global -Value 5;#Only 1 datapoint, always move to next Stage
}

function Handle-USB { #Removes Duplicates and list USB devices (seperated in the Field by Spaces)
    $USBarray = @();
    if($dataarray[$arrayline] -eq "Detected USB:"){
    $arrayline++; #Skips the line I added
    }else{
    Write-Host "Error! USB list not found"
    }
    [bool]$nextisusb =($dataarray[$arrayline] -like "USB\*"); # Before entering the While loop $nextisusb actually represents the inital line given too us
    while($nextisusb){
        $nextisusb =($dataarray[$arrayline+1] -like "USB\*") #Checks for Status of the next dataentry
        if ($USBarray -notcontains $dataarray[$arrayline].Substring(22)){ #Checks if this one is a duplicate,only adds only ∃
            if($USBarray -ne $null){$USBarray += "";} #Adds a space if this is not the first Entry
            $USBarray +=($dataarray[$arrayline]).Substring(22); #Adds only the relevant section
            #Write-Host "Adding "+ "$USBarray[$USBarray.count]";
            }
        Set-Variable -Name arrayline -Scope global -Value ($arrayline++);
    }
    Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$USBarray + ",");
    Set-Variable -Name Stage -Scope global -Value 6;
    #As we have manually advanced arraylines this function completes the Stage
}

function Handle-CurrentMonitor {
    if($dataarray[$arrayline] -like "Detecting currently * Monitor(s):"){
        $arrayline++; #Skips the line I added
    }else{
        $temp = $dataarray[$arrayline];
        Write-Host "Error! Current Monitor list not found, $temp seen instead "
    }
    [string]$Monitors = "";
    [bool]$nextismonitor =($dataarray[$arrayline] -notlike  "Past Monitors:"); # Before entering the While loop $nextismonitor actually represents the inital line given too us (after removen the one that makes it more readable)
    while($nextismonitor){
        $nextismonitor =($dataarray[$arrayline+1] -notlike  "Past Monitors:");#if this is False (meaning that the next line is not a Monitor) then this will be the last time this code is executed
        if($dataarray[$arrayline+1] -like [char]30){$nextpastmonitor = $false;}#Fixes bug of not detecting The next line being (almost empty)
        if($dataarray[$arrayline] -like "16843009*"){
            $Monitors = $Monitors , "LG_BUG"; #This catches the monitors giving back faulty S/N
        }else{
            $Monitors = $Monitors , $dataarray[$arrayline].Trim("`0");#Trimms of Null Characters
            }
        Set-Variable -Name arrayline -Scope global -Value ($arrayline++);
    }
    Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$Monitors + ",");
    
    Set-Variable -Name Stage -Scope global -Value 7;# move to next Stage
}

function Handle-PastMonitor { #Removes Duplicates, Gives a Readable header and removes known useless ones
    $PastMonitorsarray = @();
    if($dataarray[$arrayline] -like "Past Monitors:"){
        $arrayline++; #Skips the line I added
    }else{
        Write-Host "Error! Past Monitor list not found"
    }
    [string]$PastMonitors = "";
    [bool]$nextpastmonitor =($dataarray[$arrayline] -notlike   [char]30); # Before entering the While loop $nextismonitor actually represents the inital line given too us (after removing the one that makes it more readable)
    while($nextpastmonitor){
        $nextpastmonitor =($dataarray[$arrayline+1] -notlike   [char]30);# "?*" actually meanst at least 1 Character for some reason
            if(($PastMonitorsarray -notcontains $dataarray[$arrayline].Substring(22))){#Duplicatnion Detection of Easy ones 
                switch($dataarray[$arrayline].substring(0,3)){ # We use the first 3 Characters to Estimate what we have in the line
                    GSM{ # Easy LG Monitor (only needs detection for the bugged ones)
                        if($dataarray[$arrayline].substring(7,8) -notlike  "16843009"){
                            $PastMonitorsarray += " LG_SN "+$dataarray[$arrayline].substring(7,8);
                        }else{
                            $PastMonitorsarray += " LG_BUG ";
                        }
                    }
                    ENC{# Easy EIZO 
                        $PastMonitorsarray += " EIZO_SN "+$dataarray[$arrayline].substring(7,8);
                        break
                    }
                    NOE{}#FAllthrough
                    LEN{
                        #We don't care about These Monitors
                        break
                    }
                    default{#Whatever ends up here might be interesting, but is likely rubbisch
                        if($dataarray[$arrayline] -like "*?_?*"){#This might not even be needed, but this ensures that there is no error by trying to split at "_"
                            $temp =$dataarray[$arrayline].Split("_",2);
                            $PastMonitorsarray += " "+$temp[0];
                        }else{
                            Write-Host "Abnormal Past Moniotor readout found"; #If anyone ever sees this,change line to output it and start working
                        }
                    }
                    }
                }
            
        $arrayline++;
    }
    #If we are here the next line is blank (or at least without normal Characters)
    Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$PastMonitorsarray + ",");
    
    Set-Variable -Name Stage -Scope global -Value 8;#Move to next Stage
}

function Detect-Endofarray { #This is to decide wether we are done or we need to reset Stage
    <#Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$PCSN + ",");

    $Stage += 1;#Only 1 datapoint, always move to next Stag
    #>
    Write-Host "Done,skipping the rest";
    exit
}

#We do this in 2 steps First we add a Datapoint delimiter and then we Process in indiviual functions
$files = 0;
Get-ChildItem -Path R:\Inventurdaten -Filter *.txt | %{ # % is equal to ForEach-Object
$dataarray += Get-Content -Path R:\Inventurdaten\"$_" -Filter *.txt;
$dataarray += "$([char]30)"
$files +=1; #Searching arrays is not nice with wildcards, so we count the amount of inputfields here
}


if($dataarray.count -le 1){
 Write-Host "No Data Found";
 [Console]::ReadKey();
 exit;
}

#This is the main loop
 Clear-Variable -Name Currentrow
for($arrayline = 0;$arrayline -le $dataarray.count;$arrayline++){
    # $_ is (/should) be equal to $dataarray[$arrayline]
    $Currentline = $dataarray[$arrayline] #There was a pipeline here,but I demolished it.Now only this serves to read the current value for the simple functions
    if($Stage -eq 0){
        $Stage = 1;
    }
    Write-Host "Feeding $Currentline to switch";
    Write-Host "Entering Stage $stage"
    Switch ($stage){ #We iterate 7 stages (determined by what data we work on) per original file scanned and add it to one line in our output
        1 {Write-Host "Feeding $_ to time";Handle-Time -unixtime $_}
        2 {Handle-PCName -PCName $Currentline}
        3 {Handle-User -Username $Currentline}
        4 {Handle-PCSN -PCSN $Currentline}
        5 {Handle-USB } #No need to give Parameters, this function needs to Scan the next Elements of the array anyways
        6 {Handle-CurrentMonitor }#This function also needs to scan
        7 {Handle-PastMonitor }#also needs to scan and more
        8 {Detect-Endofarray}#This is a backup 
    }
    $output += $Currentrow;
}




#$testfile =Get-Content -Path R:\Inventurdaten\R91234KA-7-2.txt;


<#This is the Clean way, but I cant even remove the quotes let alone accept this output as more than garbage :(
Get-ChildItem -Path R:\Inventurdaten -Filter *.txt |%{ 
$_| Get-Content -Path R:\Inventurdaten\"$_" | ConvertTo-Csv -NoTypeInformation -Delimiter (";") -UseQuotes AsNeeded;

}
#>