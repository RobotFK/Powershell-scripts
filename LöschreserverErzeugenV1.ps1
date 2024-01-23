#By Fabian Keusen

Add-Type -assembly System.Windows.Forms
$gui = New-Object System.Windows.Forms.Form
$gui.Text ='Löschreseren erzeugen'
$gui.StartPosition = 'CenterScreen'
$gui.Width = 300
$gui.Height = 200

$VolumeInfo = New-Object System.Windows.Forms.Label
$VolumeInfo.Text = "Zu erstellendes Volumen:"
$VolumeInfo.Location = New-Object System.Drawing.Point(0,10)
$VolumeInfo.AutoSize = $true
$VolumeInfo.Font = 'Microsoft Sans Serif,10'
$gui.Controls.Add($VolumeInfo)

$VolumeAmount = New-Object System.Windows.Forms.TextBox
$VolumeAmount.Location = New-Object System.Drawing.Point(10,30)
$VolumeAmount.size = New-Object System.Drawing.Size(50,40) # Size is given in (X , Y) format
$VolumeAmount.TextAlign = "Right";
$VolumeAmount.Text = "1"
$VolumeAmount.MaxLength = 4;
$VolumeAmount.AutoSize = $true
$VolumeAmount.Font = 'Microsoft Sans Serif,10'
$gui.Controls.Add($VolumeAmount)

$VolumeType = New-Object System.Windows.Forms.ComboBox
$VolumeType.Text = "Gb"
$VolumeType.Items.Add("Gb");
$VolumeType.Items.Add("Mb");
$VolumeType.Location = New-Object System.Drawing.Point(70,30)
$VolumeType.size = New-Object System.Drawing.Size(60,40)
$VolumeType.Font = 'Microsoft Sans Serif,10'
$gui.Controls.Add($VolumeType)

$Filename = New-Object System.Windows.Forms.TextBox
$Filename.Location = New-Object System.Drawing.Point(10,90)
$Filename.size = New-Object System.Drawing.Size(200,40) 
$Filename.Text = $VolumeAmount.Text +"_"+ $VolumeType.Text.ToUpper() +"_"+"FINGER_WEG"+".dat" #Add Naming Update
$Filename.AutoSize = $true
$Filename.Font = 'Microsoft Sans Serif,10'
$gui.Controls.Add($Filename)

$FileUpdate = New-Object System.Windows.Forms.Button
$FileUpdate.Location = New-Object System.Drawing.Point(10,60)
$FileUpdate.Text = "Zu erstellenden Dateiname generieren:"
$FileUpdate.AutoSize = $true
$FileUpdate.Font = 'Microsoft Sans Serif,10'
$gui.Controls.Add($FileUpdate)
$FileUpdate.Add_Click(
{
    $rootfilename = $VolumeAmount.Text +"_"+ $VolumeType.Text.ToUpper() +"_"+"FINGER_WEG"
    $fullfilepath =(Get-Location).path+"\"+$rootfilename + ".dat"
    #$filename = $rootfilename + ".dat"
    if(!(Test-Path -Path (-join((Get-Location).path,"\",$rootfilename,".dat")))){ #Test if name is taken
        Write-Host "Created Without Appendix"
        $Filename.Text = -join($rootfilename,".dat")
    }else{
        $increment=1
        while(Test-Path -Path (-join((Get-Location).path,"\",$rootfilename,"_",$increment,".dat"))){$increment++}
        $Filename.Text = -join($rootfilename,"_",$increment,".dat")
        Write-Host "Creating Appendix"
    }
})

$repeats = New-Object System.Windows.Forms.TextBox
$repeats.Location = New-Object System.Drawing.Size(10,120)
$repeats.size = New-Object System.Drawing.Size(40,30)
$repeats.text = 1
$repeats.TextAlign = "Center"
$repeats.MaxLength = 3;
$gui.Controls.Add($repeats)

$Create = New-Object System.Windows.Forms.Button
$Create.Location = New-Object System.Drawing.Size(50,120)
$Create.Size = New-Object System.Drawing.Size(130,23)
$Create.Text = "x Dateien Erzeugen"
$Create.Font = 'Microsoft Sans Serif,10'
$gui.Controls.Add($Create)
$Create.Add_Click(
{
    $bitvolume = 1048576
    if($VolumeType.Text -eq "Gb"){$bitvolume*=1024}
    $bitvolume*= $VolumeAmount.Text
    $created = 0
    while($created -lt $repeats.text){
    fsutil file createnew $Filename.Text $bitvolume
    $FileUpdate.PerformClick()
    $created++
    }
})

$gui.ShowDialog()