$paretpath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"
$property = "Enabled"
$value = 0

$tlspath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3"
if(!(Test-Path $tlspath)){
    Write-Verbose "Creating Key TLS 1.3"
    New-Item -Path $paretpath -Name "TLS 1.3" -ItemType "folder"
}

$clientpath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client"
if(!(Test-Path $clientpath)){
    Write-Verbose "Creating Key Client"
    New-Item -Path $tlspath -Name "Client" -ItemType "folder"
}

$property_exists = $false
(Get-Item -Path $clientpath)|%{if($_.property -eq "Enabled"){$property_exists = $true}}
if($property_exists){
    Write-Verbose "Setting Property '$property' to $value"
    Set-ItemProperty -Path $clientpath -Name $property -Value $value 
}else{
    Write-Verbose "Creating Property '$property'"
    New-ItemProperty -Path $clientpath -Name $property -Value $value  -PropertyType DWORD
}