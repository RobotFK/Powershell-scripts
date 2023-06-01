#Dangerus if Used, but quite effective.
#V2 now no longer destroys Good emails
#V2.1 Added some description (namly this line that states that the code only is safe if we asume the scope of start and end to be limited to the foreach loop ;) )
#By Fabian Keusen
$Files = Get-ChildItem -Filter "*.eml"
foreach ($File in $Files){
$text =Get-Content -Path $File.Name;
$start = $text| Where-Object { $_ -like "<table id=3D*" } 
$end = $text| Where-Object { $_ -like "</table>"}
if ($start) {
$startIndex = [Array]::IndexOf($text, $start)
}
if ($end) {
$endIndex = [Array]::IndexOf($text, $end)
}
if ($end -and $start){
$newtext = $text[0..($startindex-1)] + $text[($endIndex+1)..($text.Count - 1)]
Out-File -FilePath .\$path -InputObject $newtext
Write-host "Edited" $path
}else{
Write-host "Ignored" $path
}

}

Read-Host -Prompt "Done, press enter to Close this window"