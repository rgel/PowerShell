<#
.SYNOPSIS
    Upgrade IBM server's Firmware.
	Use "IMM-Module.psm1" PowerShell module and BoMC unattended ISO image.
.DESCRIPTION
    This script upgrade IBM server's Firmware from BoMC ISO image.
	Use IMM-Module.psm1 PowerShell module and BoMC unattended ISO image.
.PARAMETER IMM
    IMM DNS name or IP address.
.PARAMETER IMMCred/Credentials (optional, default Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER IMMLog/Log (optional, change default value to meet your environment)
    Firmware upgrade process log file (txt|log).
.PARAMETER IMMConfig/Config (optional, change default value to meet your environment)
	Generic IMM config file (csv).
.PARAMETER BoMC/ISO (optional, change default value to meet your environment)
	BoMC prepared unattended Firmware ISO file.
.EXAMPLE
	.\Upgrade-IMMServerFirmware.ps1 '10.98.1.150'
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	.\Upgrade-IMMServerFirmware.ps1 -IMM '10.98.1.150' -IMMCred $immCred
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	.\Upgrade-IMMServerFirmware.ps1 -IMM '10.98.1.150' -IMMCred $immCred `
	 -Log 'C:\reports\fwUpgrade.log' -Config 'C:\reports\immSettings.csv' -ISO 'C:\BoMC_x3690X5.iso'
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
#>

#region Params

[CmdletBinding()]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
	[System.String]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,HelpMessage = "IMM Supervisor Credentials"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred = (Get-Credential -UserName customLoginID -Message "IMM Supervisor Login")
	,
	[Parameter(
		Mandatory=$false,Position=2,HelpMessage = 'Firmware upgrade process log file (txt|log)'
		)]
		[ValidatePattern('(txt$|log$)')]
		[ValidateScript({Test-Path -Path (Split-Path -Path $_) -PathType Container})]
		[Alias("Log")]
	[System.String]$IMMLog = "E:\sh\IBM\immUpgrade.log"
	,
	[Parameter(
		Mandatory=$false,Position=3,HelpMessage = 'Generic IMM config file (csv)'
		)]
		[ValidatePattern('csv$')]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("Config")]
	[System.String]$IMMConfig = "E:\sh\IBM\immSettings.csv"
	,
	[Parameter(
		Mandatory=$false,Position=4,HelpMessage = 'BoMC prepared unattended Firmware ISO file'
		)]
		[ValidatePattern('iso$')]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ISO")]
	[System.String]$BoMC = '\\NTMAHR16\srvinst$\IBM\BoMC_9.63_TFTP.iso'
)

#endregion Params

#region Load Modules

$psModules = @('IMM-Module')
Try {
	Foreach ($psModule in $psModules) {
		If ((Get-Module -Name $psModule -ErrorAction SilentlyContinue) -eq $null) {Import-Module -Name $psModule -Force -ErrorAction Stop}
	}
}
Catch {{"`n$($_.Exception.Message)"; Exit 1}}

#endregion Load Modules

#region Functions

Function Get-CurrentTime {
	Get-Date -Format "[HH:mm:ss]"
}

#endregion Functions

#region Prefly

If (Test-Path -Path $IMMLog) {clc -Path $IMMLog -Confirm:$false}
If (!(Test-Path -Path FileSystem::$BoMC -PathType Leaf)) {Exit 1}
$Host.UI.RawUI.WindowTitle = "Upgrade Firmware - '$IMM'"
If ($IMMCred) {
	$IMMLogin = $IMMCred.GetNetworkCredential().UserName
	$IMMPwd   = $IMMCred.GetNetworkCredential().Password
}

#endregion Prefly

#region Get IMM Info

$tsTime = Get-CurrentTime
Write-Host "`n$tsTime`tGathering IMM Info ..." -ForegroundColor Yellow
$immDummy = $null
$immDummy = Get-IMMInfo -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd
If ($immDummy.Serial -ne '') {
	$immDummy |ft -AutoSize
	"$tsTime`tIMM Info" >> $IMMLog
	$immDummy |fl >> $IMMLog
} Else {
	$immDummy = $null
	$immDummy = Get-IMMInfo -IMM $IMM
	If ($immDummy.Serial -ne '') {
		$immDummy |ft -AutoSize
		"$tsTime`tIMM Info" >> $IMMLog
		$immDummy |fl >> $IMMLog
	} Else {
		Write-Host "$tsTime`tFailed to communicate with IMM`n" -ForegroundColor Red
		Exit 1
	}
}

#endregion Get IMM Info

#region Create Supervisor Login Profile (if not exists yet)

If ($IMMLogin -ne 'USERID') {
	
	$login2Name  = (Get-IMMParam -IMM $IMM -Param 'LoginId.2').Value
	$login1Level = (Get-IMMParam -IMM $IMM -Param 'AuthorityLevel.1').Value

	If ($login2Name -ne $IMMLogin -and $login1Level -eq 'Supervisor' ) {
	
		$tsTime = Get-CurrentTime
		Write-Host "`n$tsTime`tCreate Supervisor Login Profile ..." -ForegroundColor Yellow
		"$tsTime`tCreate Supervisor Login Profile" >> $IMMLog
		
		$immLoginId = @()
		$immLoginId += Set-IMMParam -IMM $IMM -Confirm:$false -Param 'LoginId.2' -Value $IMMLogin
		$immLoginId += Set-IMMParam -IMM $IMM -Confirm:$false -Param 'Password.2' -Value $IMMPwd
		$immLoginId += Set-IMMParam -IMM $IMM -Confirm:$false -Param 'AuthorityLevel.2' -Value Supervisor
		$immLoginId += Set-IMMParam -IMM $IMM -Confirm:$false -Param 'AuthorityLevel.1' -Value ReadOnly -IMMLogin $IMMLogin -IMMPwd $IMMPwd
		$immLoginId |ft -AutoSize
		$immLoginId |fl >> $IMMLog
	}
	
} Else {
	$tsTime = Get-CurrentTime
	Write-Host "`n$tsTime`tCustom Supervisor Login Profile already exists ..." -ForegroundColor Yellow
	"$tsTime`tCustom Supervisor Login Profile already exists" >> $IMMLog
	$IMMLogin = 'USERID'
	$IMMPwd   = 'PASSW0RD'
}

#endregion Create Supervisor Login Profile

#region Save and Change BootOrder ("CD/DVD Rom" first)

$tsTime = Get-CurrentTime
Write-Host "`n$tsTime`tSave and Change Boot Order ..." -ForegroundColor Yellow
$origBO = Get-IMMServerBootOrder -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd
$origBO |ft -AutoSize
"$tsTime`tOriginal Boot Order" >> $IMMLog
$origBO |fl >> $IMMLog

If ($origBO.Boot1 -ne 'CD/DVD Rom') {
	$needChangeBO = $true
	$cdBO = Set-IMMServerBootOrder -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd -Confirm:$false
	$tsTime = Get-CurrentTime
	If ($cdBO.Boot1 -ne '') {
		Write-Host "$tsTime`tBoot Order successfully changed" -ForegroundColor Green
		"$tsTime`tBoot Order successfully changed" >> $IMMLog
	} Else {
		Write-Host "$tsTime`tFailed to change Boot Order`n" -ForegroundColor Red
		"$tsTime`tFailed to change Boot Order" >> $IMMLog
		Exit 1
	}
} Else {
	$needChangeBO = $false
	Write-Host "$tsTime`tNo need to change Boot Order" -ForegroundColor Green
	"$tsTime`tNo need to change Boot Order" >> $IMMLog
}

#endregion Save and Change BootOrder ("CD/DVD Rom" first)

#region Set Generic Enterprise settings from config file

$tsTime = Get-CurrentTime
Write-Host "`n$tsTime`tSet Generic Enterprise IMM parameters from config file '$IMMConfig' ..." -ForegroundColor Yellow
"$tsTime`tSet Generic Enterprise IMM parameters from config file '$IMMConfig'" >> $IMMLog

$i = 0
Import-Csv $IMMConfig |% {

	$key   = $_.IMMKey
	$value = $_.IMMValue
	$i += 1
	$immDummy = $null
	$immDummy = Set-IMMParam -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd -Param $key -Value $value -Confirm:$false
	If ($immDummy.Value -ne '') {Write-Host "`t[$i] $($immDummy.Param) = $($immDummy.Value)" -ForegroundColor Green}
	Else                        {Write-Host "`t[$i] $($immDummy.Param) = $($immDummy.Value)" -ForegroundColor Red}
	"`t[$i] '$($immDummy.Param)' = '$($immDummy.Value)'" >> $IMMLog
}

#endregion Set Generic Enterprise settings from config file

#region Set IMM Name

If ($IMM -match "^[a-zA-Z]+.*") {

	$tsTime = Get-CurrentTime
	Write-Host "`n$tsTime`tSet IMM Name ..." -ForegroundColor Yellow
	"$tsTime`tSet IMM Name" >> $IMMLog

	$immDummy = $null
	$immDummy = Set-IMMParam -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd -Param 'IMMInfo_Name' -Value $IMM -Confirm:$false
	If ($immDummy.Value -ne '') {Write-Host "`t[1] $($immDummy.Param) = $($immDummy.Value)" -ForegroundColor Green}
	Else                        {Write-Host "`t[1] $($immDummy.Param) = $($immDummy.Value)" -ForegroundColor Red}
	"`t[1] '$($immDummy.Param)' = '$($immDummy.Value)'" >> $IMMLog
	
	$immDummy = $null
	$immDummy = Set-IMMParam -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd -Param 'HostName1' -Value $IMM -Confirm:$false
	If ($immDummy.Value -ne '') {Write-Host "`t[2] $($immDummy.Param) = $($immDummy.Value)" -ForegroundColor Green}
	Else                        {Write-Host "`t[2] $($immDummy.Param) = $($immDummy.Value)" -ForegroundColor Red}
	"`t[2] '$($immDummy.Param)' = '$($immDummy.Value)'" >> $IMMLog
}

#endregion Set IMM Name

#region Upgrade Firmware

### Restart IMM previous to ISO mount to avoid upgrade process fail ###
$tsTime = Get-CurrentTime
Write-Host "`n$tsTime`tRestarting IMM ... This may take a few minutes" -ForegroundColor Yellow
$immDummy = $null
$immDummy = Restart-IMM -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd -Confirm:$false
If ($immDummy.PowerState -eq 'Restarted') {
	$tsTime = Get-CurrentTime
	Write-Host "$tsTime`tIMM restarted successfully" -ForegroundColor Green
	"$tsTime`tIMM restarted successfully" >> $IMMLog
	Start-Sleep -Seconds 120
} Else {Write-Host "$tsTime`tIMM failed to restart, will continue without it" -ForegroundColor Yellow}


### Mount BoMC ISO image to IMM's Virtual Media Drive ###
$tsTime = Get-CurrentTime
Write-Host "`n$tsTime`tMounting BoMC ISO file to IMM's Virtual Media Drive ..." -ForegroundColor Yellow
If (Get-IMMISO -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd) {Unmount-IMMISO -IMM $IMM}
$immDummy = $null
$immDummy = Mount-IMMISO -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd -ISO $BoMC
If ($immDummy.ISO -ne '') {
	Write-Host "$tsTime`tBoMC ISO '$BoMC' successfully mounted" -ForegroundColor Green
	"$tsTime`tBoMC ISO '$BoMC' successfully mounted to IMM" >> $IMMLog
} Else {
	Write-Host "$tsTime`tFailed to mount BoMC ISO to IMM`n" -ForegroundColor Red
	"$tsTime`tFailed to mount BoMC ISO to IMM" >> $IMMLog
	### Revert original Boot Order and Exit ###
	If ($needChangeBO) {

		$tsTime = Get-CurrentTime
		Write-Host "`n$tsTime`tReverting to the Original Boot Order ..." -ForegroundColor Yellow
		$immDummy = $null
		$immDummy = Set-IMMServerBootOrder -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd -Confirm:$false `
		-Boot1 $origBO.Boot1 -Boot2 $origBO.Boot2 -Boot3 $origBO.Boot3 -Boot4 $origBO.Boot4

		If ($immDummy.Boot1 -eq $origBO.Boot1) {
			Write-Host "$tsTime`tOriginal Boot Order reverted successfully" -ForegroundColor Green
			"$tsTime`tOriginal Boot Order reverted successfully" >> $IMMLog
		} Else {
			Write-Host "$tsTime`tFailed to revert Original Boot Order" -ForegroundColor Red
			"$tsTime`tFailed to revert Original Boot Order" >> $IMMLog
		}
	}
	Exit 1
}


### Reboot IBM server ###
$tsTime = Get-CurrentTime
Write-Host "`n$tsTime`tRebooting IBM server ..." -ForegroundColor Yellow
$immDummy = $null
$immDummy = Reboot-IMMServerOS -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd -Confirm:$false
If ($immDummy.PowerState -eq 'Rebooted') {
	Write-Host "$tsTime`tServer successfully rebooted" -ForegroundColor Green
	"$tsTime`tServer successfully rebooted" >> $IMMLog
} Else {
	Write-Host "$tsTime`tFailed to reboot server`n" -ForegroundColor Red
	"$tsTime`tFailed to reboot server" >> $IMMLog
	Exit 1
}


### Take a time for Firmware upgrade ###
$waitIMMmin = 40
$waitIMMsec = $waitIMMmin*60
$tsTime = Get-CurrentTime
Write-Host "`n$tsTime`tWaiting $waitIMMmin minutes for Firmware upgrade to finish ..." -ForegroundColor Yellow
Start-Sleep -Seconds $waitIMMsec


### Waiting for the server to Power Off 1-st time (after IMM upgrade) ###
$tsTime = Get-CurrentTime
Write-Host "`n$tsTime`tWaiting for server to Power Off ..." -ForegroundColor Yellow
$immDummy = $null
Do
{	Start-Sleep -Seconds 60
	$immDummy = Get-IMMServerPowerState -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd
}	Until ($immDummy.PowerState -eq 'PoweredOff')
$tsTime = Get-CurrentTime
Write-Host "$tsTime`tIBM Server Powered Off (IMM upgraded)" -ForegroundColor Green
"$tsTime`tIBM Server Powered Off (IMM upgraded)" >> $IMMLog


### Power On the server 1-st time (after IMM upgrade) ###
Start-Sleep -Seconds 120
$tsTime = Get-CurrentTime
Write-Host "`n$tsTime`tTrying to Power On the server 1-st time ..." -ForegroundColor Yellow
$immDummy = $null
Do
{	Start-IMMServer -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd |Out-Null
	Start-Sleep -Seconds 10
	$immDummy = Get-IMMServerPowerState -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd
}	Until ($immDummy.PowerState -eq 'PoweredOn')
$tsTime = Get-CurrentTime
Write-Host "$tsTime`tIBM Server Powered On (after IMM upgrade)" -ForegroundColor Green
"$tsTime`tIBM Server Powered On  (after IMM upgrade)" >> $IMMLog


### Waiting 4 cycles (turned on - turned off) ###
$tsTime = Get-CurrentTime
Write-Host "`n$tsTime`tWaiting for Host Power 'turned on-turned off' cycles ..." -ForegroundColor Yellow
Start-Sleep -Seconds 900


### Power On the server 2-nd time if not already Powered On (after UEFI upgrade) ###
$tsTime = Get-CurrentTime
Write-Host "`n$tsTime`tTrying to Power On the server 2-nd time ..." -ForegroundColor Yellow
$immDummy = $null
Do
{	Start-IMMServer -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd
	Start-Sleep -Seconds 10
	$immDummy = Get-IMMServerPowerState -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd
}	Until ($immDummy.PowerState -eq 'PoweredOn')
$tsTime = Get-CurrentTime
Write-Host "$tsTime`tUpgrade finished and IBM Server Powered On" -ForegroundColor Green
"$tsTime`tUpgrade finished and IBM Server Powered On" >> $IMMLog

#endregion Upgrade Firmware

#region Revert to the Original Boot Order

If ($needChangeBO) {

	$tsTime = Get-CurrentTime
	Write-Host "`n$tsTime`tReverting to the Original Boot Order ..." -ForegroundColor Yellow
	$immDummy = $null
	$immDummy = Set-IMMServerBootOrder -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd -Confirm:$false `
	-Boot1 $origBO.Boot1 -Boot2 $origBO.Boot2 -Boot3 $origBO.Boot3 -Boot4 $origBO.Boot4

	If ($immDummy.Boot1 -eq $origBO.Boot1) {
		Write-Host "$tsTime`tOriginal Boot Order reverted successfully" -ForegroundColor Green
		"$tsTime`tOriginal Boot Order reverted successfully" >> $IMMLog
	} Else {
		Write-Host "$tsTime`tFailed to revert Original Boot Order" -ForegroundColor Red
		"$tsTime`tFailed to revert Original Boot Order" >> $IMMLog
	}
}

#endregion Revert to the Original Boot Order
