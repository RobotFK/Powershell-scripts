#By Fabian Keusen
#V1.0 First relase

#cd C:\Daten\Docconvert #Debuging folder

$oldword = (Get-ChildItem|where {$_.Name -like "*.doc"}|Measure-Object).Count
$oldexel = (Get-ChildItem|where {$_.Name -like "*.xls"}|Measure-Object).Count

Write-Host "$($oldword) Word and $($oldexel) Exel files applicable"

$delete = $false
if($oldword -eq 0 -and $oldexel -eq 0){Write-Host "No files found";Wait-Event;Exit}
if($oldword -ne 0){$oldword *= [int]((Read-Host "Convert Word .doc files to .docx ?(y/n)") -eq "y")}
if($oldexel -ne 0){$oldexel *= [int]((Read-Host "Convert Exel .xls files to .xlsx ?(y/n)") -eq "y")}
if((Read-Host "To Delete old files after conversion type 'yes'") -eq "yes"){$delete = $true}
$count= 0

if($oldword -ne 0){#Word
    $word = New-Object -ComObject word.application
    $word.visible = $false
    $wformat = [Microsoft.Office.Interop.Word.WdSaveFormat]::wdFormatDocumentDefault #Value 65535
    Get-ChildItem|where {$_.Name -like "*.doc"}|%{
        if(Test-Path -Path ($_.FullName+'x')){Wrtite-host "$($_.Name+'x') already exist,skipping";continue}
        $count++
        Write-Host "Converted $($_.Name)"
        $path = $_.FullName.substring(0,($_.FullName).lastindexOf(“.”))
        $doc = $word.documents.open($_.FullName)
        $doc.saveas2($path,$wformat)
        $doc.Close()
        Remove-Variable -Name doc
        if($delete){Remove-Item $_.FullName}
    }
    $word.Quit()
    Remove-Variable -Name word
}

if($oldexel -ne 0){#Exel
    $exel = New-Object -ComObject excel.application
    $exel.visible = $false
    $eformat = [microsoft.Office.Interop.Excel.XlFileFormat]::xlOpenXMLStrictWorkbook#Value 61
    Get-ChildItem|where {$_.Name -like "*.xls"}|%{
        if(Test-Path -Path ($_.FullName+'x')){Wrtite-host "$($_.Name+'x') already exist,skipping";continue}
        $count++
        Write-Host "Converted $($_.Name)"
        $path = $_.FullName.substring(0,($_.FullName).lastindexOf(“.”))
        $sheet = $exel.workbooks.open($_.FullName)
        $sheet.saveas($path,$eformat)
        $sheet.Close()
        Remove-Variable -Name sheet
        if($delete){Remove-Item $_.FullName}
    }
    $exel.Quit()
    Remove-Variable -Name exel
}

Write-Host "Converted $($count) Files. Done"

if($count -gt 50){Write-Host "Restard for garbage collection recommended"}
Wait-Event