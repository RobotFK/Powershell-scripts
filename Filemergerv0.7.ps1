#by Fabian Keusen under GNU General Public License
#v0.1 Inital Work (Framework and Handle-Time)
#v0.2 Added license and Funtion 2-7
#v0.3 Added Funtion 8, fixed to output conversion and Fixed a lot of wrongs
#v0.4 Cleaned up Username And Rownames
#v0.5 Added USB Filters
#v0.6 Remade USB Filters into swtich cases to make it more understandable and Add handle more cases (incomplete)
#v0.7 Transiotion Stage 6 to give out ounly the first 3 monitors, fixed Stage 5 crash and made tighter switches

<#Todo: 
Make Fancy ?
#>

#This  $([char]30) Ascii character is designed for this delimiting Rows
#We do this in 2 steps First: We add a Datapoint delimiter and then we Process it in indiviual functions
$dataarray  = @(); #Used for convertion
$column = 0; #Amount of Files+1 to process
[int]$global:arrayline = 1 ;#Current line we are reading out (This need acess so we can skip on multiline readouts)
$global:Currentrow = "Time,PC-Name,Username,PC-SN,Interesting USB,Monitor1,Monitor2,Monitor3,PastMonitors" #This will be how the data is stored each line,this one is also the top line
$global:Stage = 0; # In whitch part of the Possible 8 we are currently writing
$global:output = @(); # Finall output we fill each Element with a line;
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
    Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$Username.substring(6,6) + ",");

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
        Set-Variable -Name arrayline -Scope global -Value ($arrayline+1); #Skips the line I added
    }else{
    Write-Host "Error! USB list not found"
    }
    [bool]$nextisusb =($dataarray[$arrayline] -like "USB\*"); # Before entering the While loop $nextisusb actually represents the inital line given too us
    while($nextisusb){
        $nextisusb =($dataarray[$arrayline+1] -like "USB\*") #Checks for Status of the next dataentry
        if ($USBarray -notcontains $dataarray[$arrayline].Substring(22)){ #Checks if this one is a duplicate,only adds only ∃
            if($USBarray -ne $null){$USBarray += "";} #Adds a space if this is not the first Entry
                $relevant = $false ;# This Cuts down on the Volume of the switch case, could also rather be coined "not irrelevant" 
                switch($dataarray[$arrayline].Substring(8,4)){#We adress specific Vendors
                    03F0 {# HP
                        switch($dataarray[$arrayline].Substring(18,4)){#We adress specific Devices
                        2B4A{break;} #Keyboard
                        default{$relevant = $true}
                        }}
                    046D {# Logitec
                        switch($dataarray[$arrayline].Substring(18,4)){#We adress specific Devices
                        C31C{break;}#Keyboard
                        default{$relevant = $true}
                        }}
                    8087{#Intel
                        break;
                        }
                    17EF{#Lenovo
                        break;
                        }
                    1B17{#Is Plusonic but gives SHENZHEN e-loam VendorID
                        if ($USBarray -notcontains "Plusonic-cam"){ $USBarray += "Plusonic-cam"}#Manuall Adding
                        break;
                        }
                    04B8{}#TheFollowing ones might be able to catch Epson stuff
                    0570{}
                    1208{}
                    03F8{
                        $relevant = $true;
                        break;
                        }
                }
            if($relevant){
                if ($USBarray -notcontains $dataarray[$arrayline].Substring(22)){ #Checks if this one is a duplicate,only adds only ∃
                    if($USBarray -ne $null){
                        $USBarray += ""; #Adds a space if this is not the first Entry
                    }
                    if($dataarray[$arrayline] -notlike "*&?"){ #Removes the Results with & as the secondlast Letter
                        $USBarray +=($dataarray[$arrayline]).Substring(22); #Adds only the relevant section
                    }
                }
            }
        
        }
        Set-Variable -Name arrayline -Scope global -Value ($arrayline++);
    }
    Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$USBarray + ",");
    Set-Variable -Name Stage -Scope global -Value 6;
    #As we have manually advanced arraylines this function completes the Stage
}

function Handle-CurrentMonitor {
    if($dataarray[$arrayline] -like "Detecting currently * Monitor(s):"){
        Set-Variable -Name arrayline -Scope global -Value ($arrayline+1); #Skips the line I added
    }else{
        $temp = $dataarray[$arrayline];
        Write-Host "Error! Current Monitor list not found, $temp seen instead "
    }
    [string]$Monitors = "";
    [int]$Monitorsprogress = 0; # This helps us only get 3 Monitors
    [bool]$nextismonitor =($dataarray[$arrayline] -notlike  "Past Monitors:"); # Before entering the While loop $nextismonitor actually represents the inital line given too us (after removen the one that makes it more readable)
    while($nextismonitor){
        $nextismonitor =($dataarray[$arrayline+1] -notlike  "Past Monitors:");#if this is False (meaning that the next line is not a Monitor) then this will be the last time this code is executed
        if($dataarray[$arrayline+1] -like [char]30){$nextpastmonitor = $false;}#Fixes bug of not detecting The next line being (almost empty)
        if($dataarray[$arrayline] -like "16843009*"){
            $Monitors = $Monitors , "LG_BUG",","; #This catches the monitors giving back faulty S/N
        }elseif($dataarray[$arrayline] -like "0`0*"){#This is the Internal one we write nothing and dont count it
            $Monitorsprogress--;
        }else{
            $Monitors = $Monitors , $dataarray[$arrayline].Trim("`0"),",";#Trimms of NULL Characters
            }
        $Monitorsprogress++;#Increase as  we  have just added a monitor
        if($Monitorsprogress -eq 3){$nextismonitor = $False;$Monitors = $Monitors.TrimEnd(",")} #Here we just care about breaking the while loop and removing the last ","
        Set-Variable -Name arrayline -Scope global -Value ($arrayline+1);
    
    }
    for(;$Monitorsprogress -lt 2;$Monitorsprogress++){$Monitors = $Monitors ,","}#Ah yeah, efficent code
    Write-Host "Monitors: $Monitors"
    Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$Monitors+"," );
    Set-Variable -Name arrayline -Scope global -Value ($arrayline-1);#Uhh ... yeah this just stops the for loop from skipping a line here. Definitly not best practice
    Set-Variable -Name Stage -Scope global -Value 7;# move to next Stage
}

function Handle-PastMonitor { #Removes Duplicates, Gives a Readable header and removes known useless ones
    $PastMonitorsarray = @();
    if($dataarray[$arrayline] -like "Past Monitors:"){
        Set-Variable -Name arrayline -Scope global -Value ($arrayline++); #Skips the line I added
    }else{
        $temp = $dataarray[$arrayline];
        Write-Host "Error! Past Monitor list not found,  $temp seen instead"
    }
    [string]$PastMonitors = "";
    [bool]$nextpastmonitor =($dataarray[$arrayline] -notlike   [char]30); # Before entering the While loop $nextismonitor actually represents the inital line given too us (after removing the one that makes it more readable)
    while($nextpastmonitor){
        $nextpastmonitor =($dataarray[$arrayline+1] -notlike   [char]30);# "?*" actually meanst at least 1 Character for some reason
            if($dataarray[$arrayline].Length  -ge 15){
                if(($PastMonitorsarray -notcontains $dataarray[$arrayline].Substring(7,8))){#Duplicatnion Detection of Easy ones 
                    switch($dataarray[$arrayline].substring(0,3)){ # We use the first 3 Characters to Estimate what we have in the line
                    GSM{ # Easy LG Monitor (only needs detection for the bugged ones)
                        if($dataarray[$arrayline].substring(7,8) -notlike  "16843009"){
                            $PastMonitorsarray += " LG_SN:"+$dataarray[$arrayline].substring(7,8);
                        }else{
                            $PastMonitorsarray += " LG_BUG ";
                        }
                    }
                    ENC{# Easy EIZO 
                        $PastMonitorsarray += " EIZO_SN:"+$dataarray[$arrayline].substring(7,8);
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
                            Write-Host "Abnormal Past Moniotor readout found"; #If anyone ever sees this,change line give more info and start working
                        }
                    }
                    }
                }#Finding a Duplication
            }else{ 
                    $temp = $dataarray[$arrayline].Length
                    Write-Host "PastMonitor of too short type detected: $temp"
                }
        Set-Variable -Name arrayline -Scope global -Value ($arrayline++);
        #Write-Host "Stage 7 has incremented Arrayline to $arrayline"
    }
    #If we are here the next line is blank (or at least without normal Characters)
    Set-Variable -Name Currentrow -Scope global -Value ($currentrow +$PastMonitorsarray + ",");
    Set-Variable -Name Stage -Scope global -Value 8;#Move to next Stage
}

function Detect-Endofarray { #This is to decide wether we are done or we need to reset Stage, Fix errors or End the programm
<#
    Write-Host "Adding Current row to output:";
    $output[$Column]
    Write-Host "";
    Set-Variable -Name output -Scope global -Value $output ,$Currentrow; # We always add our Row to the array
    #>

    if($dataarray[$arrayline+2] -ne $null){ #If there are 2 Free we asume to be at the end of the array
        Set-Variable -Name arrayline -Scope global -Value ($arrayline++);
    	Set-Variable -Name Stage -Scope global -Value 1;
        #Write-Host "More Data found,reseting Stage, with next line $arrayline";
    }else{
    Add-content -path C:\Daten\Output.txt -value $output;
    Write-Host "Done.Exiting script";
    [Console]::ReadKey();
    exit
    }
}

#This imports our Data
$columns = 0;
Get-ChildItem -Path R:\Inventurdaten -Filter *.txt | %{ # % is equal to ForEach-Object
if($_.Name -ne "Output.txt"){#Stops it from Eating the Output aswell
$dataarray += Get-Content -Path R:\Inventurdaten\"$_" -Filter *.txt;
$dataarray += "$([char]30)"
$columns +=1; #Searching arrays is not nice with wildcards, so we count the amount of inputfields here
}else{# Well not really, but ensures the User knows of the destruction ;)
Write-Host "Output already Found.This WILL Hurt. Are you sure of what you are doing ?";
read-host “Press ENTER to continue...”;}
}


if($dataarray.count -le 1){
 Write-Host "No Data Found";
 exit;
}

#This is the main loop, the end condition is really just as a backup
 Clear-Variable -Name Currentrow
for($arrayline = 0;$arrayline -le $dataarray.count;$arrayline++){

[int]$progress = (($arrayline+1)/$dataarray.count)*100
#Write-Host "$progress"
Write-Progress -Activity "Total Progress" -Status "$progress% Complete:" -PercentComplete $progress
Write-Progress -Id 6 -Activity "File Progress" -Status "$stage/8 Complete:" -PercentComplete ($stage/8*100)
Start-Sleep -Milliseconds 10 #This decides how slow it goes

#$temp = $dataarray[$arrayline]
#Write-Host "Entering loop with Arrayline $arrayline and Value $temp"
    # $_ is (/should) be equal to $dataarray[$arrayline]
    $Currentline = $dataarray[$arrayline] #There was a pipeline here,but I demolished it.Now only this serves to read the current value for the simple functions
    if($Stage -eq 0){
        $Stage = 1;
    }
    # Write-Host "Feeding $Currentline to switch"; #Used to test if we handed over the correct Thing
    Write-Host "Entering Stage $stage"
    Switch ($stage){ #We iterate 7 stages (determined by what data we work on) per original file scanned and add it to one line in our output
        1 {Handle-Time -unixtime $Currentline}
        2 {Handle-PCName -PCName $Currentline}
        3 {Handle-User -Username $Currentline}
        4 {Handle-PCSN -PCSN $Currentline}
        5 {Handle-USB } #No need to give Parameters, this function needs to Scan the next Elements of the array anyways
        6 {Handle-CurrentMonitor }#This function also needs to scan
        7 {Handle-PastMonitor }#also needs to scan and more
        8 {#This is to see if there are more files
            $output += $currentrow; #If done in the Funciton I cant seem to interact with specific array positions
            #Write-Host "Currentrow is $currentrow"
            Clear-Variable -Name Currentrow; #We clear Currentrow to fill it again
            Detect-Endofarray
            }
    }
    #$temp = $dataarray[$arrayline]
    #Write-Host "Current line $arrayline ends on $temp "
}
Write-Host "If this is seen we seem to have encountered an Error"
Write-Host "End of Loop due to $arrayline being less||= than $dataarray.count "

Add-content -path C:\Daten\Output.txt -value $output;