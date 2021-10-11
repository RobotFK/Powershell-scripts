# by Fabian Keusen under GNU General Public License
#V1 Added Base Functions
#V2 Added 2 Additional Sniffers and a Dynamic naming system
#V2.2 Added timestamp to Prevent duplication, and Curren user
#V2.3 Added Timebased self-termination and 
#Changed duplication prevention to Usb count (as this is the only dynamic amount that should change)
#V2.4 Propper path now
#V2.5 Getting Current Monitor S/N
#v2.6 Added Feedback on Termination, fixed bad variable names (to not intersect)
#v2.7 Removed limiter
#v2.8 Fixed Current Monitor on Dynamic amount of Monitors
$year = Get-date -UFormat "%Y";
if($year -ne  2021){ #Stops Code if year is no longer 2021
 Write-Host "Execution Post Termination Date (31.12.2021)";
 [Console]::ReadKey();
 exit;
}

$time = Get-Date -UFormat "%s";
$pcname = $env:computername;

$user = "User: " + $env:UserName;

$pctemp = get-WmiObject Win32_BIOS | Select SerialNumber;
$serial = $pctemp.SerialNumber;

#Finds out How many Usb devices are detected by the middleware
$ucount = get-itemPropertyValue Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\usbccgp\Enum -name Count;
$ucount--;#Needed because Count starts at 1 but Reg-keys start with Item 0

#Duplication test interlude
if(Test-Path -path R:\Inventurdaten\"$serial-$ucount".txt -PathType Leaf){
 Write-Host "Duplication Detected";
 [Console]::ReadKey();
 exit;
}

#Creation of Usb devices list
$usbarray = @();
$usbarrayintro += "Detected USB:";
for ($i = 0; $i -le $ucount; $i++){
    $usbarray += Get-ItemPropertyValue Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\usbccgp\Enum -name $i;
}
#$usbarray = $usbarray.substring(22); Not used in collection anymore
#$usbarray;

#Creation of Past Monitors devices list
$array = Get-childitem Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\ScaleFactors\* -name;
$Monitorarray = "Past Monitors:",$array;
#$Monitorarray = "Past Monitors:",  $array.Substring(7,12); Not used in collection anymore

#This Horrible thing extracts The Current Monitor Serial Number,Feeds it through some channels and Finally makes it Readable to humans
$Monitorsn = @();
$currentmonitorsntemp = Get-WmiObject -Property SerialNumberID -Namespace "root/WMI" WmiMonitorID |Select-Object  SerialNumberID;
$currentmonitoramount = ($currentmonitorsntemp.SerialNumberID.count /16);

$Monitorsn += ("Detecting currently "+ $currentmonitoramount + " Monitor(s):");
#Write-Host $Monitorsn;
for ($i = 1; $i -le $currentmonitoramount; $i++){ #Starts at 1 and Fills in all 16 uint Monitorsn segements into a Array
    Clear-Variable -name temp;
    for($j = 1; $j -ne 16; $j++){
    #if ($currentmonitorsntemp[$i-1].SerialNumberID[($j-1)] -ne 0){ Not used anymore due to destructive behavior
        $temp = -Join  ($temp , [char]$currentmonitorsntemp[$i-1].SerialNumberID[($j-1)]); #converts to char and adds
    #}
    }
    <#
    This was used to debug:
    Write-Host "Before:" $Monitorsn;
    $Monitorsn += $temp;
    Write-Host "After:" $Monitorsn;
    #>
} # The Final data is saved in Monitorsn

#Starting Writing Process

Add-content -path R:\Inventurdaten\"$serial-$ucount".txt -value $time,$pcname, $User, $serial,$usbarrayintro, $usbarray, $monitorsn;
#$Monitorarray added seperatly to fix something
Add-content -path R:\Inventurdaten\"$serial-$ucount".txt -value $Monitorarray;


Write-Host "Finished Collecting Hardware info";
[Console]::ReadKey();
