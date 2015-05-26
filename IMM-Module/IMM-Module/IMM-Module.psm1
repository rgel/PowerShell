<#
.NOTES
	IMM-Module ChangeLog
	
	1.0 - 17/05/2015 - Initial release
#>

#region Global variables used by all functions in the module

<#
Change these settings to meet your environment:
$ASUDIR        - Folder that contains extracted IBM ASU package
$ASU,$RDM,$RDU - ASU package utilities
$Plink         - plink.exe utility
#>

$ASUDIR = "E:\sh\IBM\ASU"
$ASU    = "$ASUDIR\asu64.exe"
$RDM    = "$ASUDIR\rdmount.exe"
$RDU    = "$ASUDIR\rdumount.exe"
$Plink  = "$ASUDIR\plink.exe"

#endregion Global variables used by all functions in the module

Function Get-IMMServerPowerState {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function retrives IBM server's Powerstate.
.DESCRIPTION
    This function retrives IBM server's Powerstate.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Get-IMMServerPowerState esxhai1r -IMMCred (Get-Credential -UserName yourlogin -Message "IMM credentials")
.EXAMPLE
	Get-IMMServerPowerState -IMM "esxhai1r","esxhai2r" -IMMLogin yourlogin -IMMPwd yourpassword |sort PowerState |ft -AutoSize
.EXAMPLE
	Get-Content -Path "C:\reports\imm.txt" `
	|Get-IMMServerPowerState -IMMCred (Get-Credential -UserName yourlogin -Message "IMM credentials")
.EXAMPLE
	$immCol = Get-IMMSubnet "10.98.1.0" 120 150 |Get-IMMServerPowerState -IMMCred $immCred
	$immCol |sort PowerState,IMM |ft
	$immCol |? {$_.PowerState -eq 'PoweredOn'} |select IMM |ft -HideTableHeaders
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 2 Properties: IMM,PowerState.
	PowerState may be one of the three options: PoweredOn,PoweredOff,Unknown.
	The major reasons for 'Unknown' power state are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$i = 0
}

Process {

	Foreach ($module in $IMM) {
	
		$ASUCmd       = "immapp powerstate"
		$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
		$ASUPrint     = ''
		$ASUReturn    = "Unknown"
		$regexSuccOn  = "currently\sOn!"
		$regexSuccOff = "currently\sOff!"
		
		$i += 1
		Write-Progress -Activity "Gathering Server Power State" -Status "[$i] $module"
		
		$ASUPrint = Invoke-Expression -Command $ASUCmdLine
		
		Switch -regex ($ASUPrint) {
			$regexSuccOn  {$ASUReturn = "PoweredOn";  Break}
			$regexSuccOff {$ASUReturn = "PoweredOff"; Break}
		}

		$Properties = [ordered]@{
			IMM        = $module
			PowerState = $ASUReturn
		}
		$Object = New-Object PSObject -Property $Properties
		$Object
	}

}

} #EndFunction Get-IMMServerPowerState #1

Function Start-IMMServer {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function Power On IBM server.
.DESCRIPTION
    This function Power On IBM server.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Start-IMMServer esxhai1r -IMMCred (Get-Credential -UserName yourlogin -Message "IMM credentials")
.EXAMPLE
	Start-IMMServer -IMM "esxhai1r","esxhai2r" -IMMLogin yourlogin -IMMPwd yourpassword |sort PowerState |ft -AutoSize
.EXAMPLE
	Get-Content -Path "C:\reports\imm.txt" `
	|Start-IMMServer -IMMCred (Get-Credential -UserName yourlogin -Message "IMM credentials")
.EXAMPLE
	$immCol = Get-IMMSubnet "10.98.1.0" 120 150 |Start-IMMServer -IMMCred $immCred
	$immCol |sort PowerState,IMM |ft
	$immCol |? {$_.PowerState -eq 'PoweredOff'} |select IMM |ft -HideTableHeaders
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 2 Properties: IMM,PowerState.
	PowerState may be one of the two options: PoweredOn,Unknown.
	The major reasons for 'Unknown' power state are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$i = 0
}

Process {

	Foreach ($module in $IMM) {
	
		$ASUCmd       = "immapp Poweronos"
		$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
		$ASUPrint     = ''
		$ASUMatch     = $null
		$regexSuccess = "Server\sPowered\sOn"
		
		$i += 1
		Write-Progress -Activity "Powering On Server" -Status "[$i] $module"
		
		$ASUPrint = Invoke-Expression -Command $ASUCmdLine
		$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

		If ($ASUMatch.Success) {$ASUReturn = "PoweredOn"} Else {$ASUReturn = "Unknown"}

		$Properties = [ordered]@{
			IMM        = $module
			PowerState = $ASUReturn
		}
		$Object = New-Object PSObject -Property $Properties
		$Object
	}

}

} #EndFunction Start-IMMServer #2

Function Shutdown-IMMServerOS {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function Shutdown IBM server's OS.
.DESCRIPTION
    This function Shutdown IBM server's Operating System.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Shutdown-IMMServerOS esxhai1r -IMMCred (Get-Credential -UserName yourlogin -Message "IMM credentials")
.EXAMPLE
	Shutdown-IMMServerOS -IMM "esxhai1r","esxhai2r" -IMMLogin yourlogin -IMMPwd yourpassword |sort PowerState |ft -AutoSize
.EXAMPLE
	Get-Content -Path "C:\reports\imm.txt" `
	|Shutdown-IMMServerOS -IMMCred (Get-Credential -UserName yourlogin -Message "IMM credentials")
.EXAMPLE
	$immCol = Get-IMMSubnet "10.98.1.0" 120 150 |Shutdown-IMMServerOS -IMMCred $immCred -Confirm:$false
	$immCol |sort PowerState,IMM |ft
	$immCol |? {$_.PowerState -eq 'PoweredOff'} |select IMM |ft -HideTableHeaders
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 2 Properties: IMM,PowerState.
	PowerState may be one of the two options: PoweredOff,Unknown.
	The major reasons for 'Unknown' power state are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR',ConfirmImpact='High',SupportsShouldProcess=$true)]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$i = 0
}

Process {

	Foreach ($module in $IMM) {
	
		If ($PSCmdlet.ShouldProcess($IMM,"Shutdown OS and Poweroff Server")) {
	
			$ASUCmd       = "immapp Poweroffos"
			$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
			$ASUPrint     = ''
			$ASUMatch     = $null
			$regexSuccess = 'Server\sPowered\soff'
			
			$i += 1
			Write-Progress -Activity "Powering Off Server" -Status "[$i] $module"
			
			$ASUPrint = Invoke-Expression -Command $ASUCmdLine
			$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

			If ($ASUMatch.Success) {$ASUReturn = "PoweredOff"} Else {$ASUReturn = "Unknown"}

			$Properties = [ordered]@{
				IMM        = $module
				PowerState = $ASUReturn
			}
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
	}

}

} #EndFunction Shutdown-IMMServerOS #3

Function Reboot-IMMServerOS {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function Reboot IBM server's OS.
.DESCRIPTION
    This function Reboot IBM server's Operating System.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Reboot-IMMServerOS esxhai1r -IMMCred (Get-Credential -UserName yourlogin -Message "IMM credentials")
.EXAMPLE
	Reboot-IMMServerOS -IMM "esxhai1r","esxhai2r" -IMMLogin yourlogin -IMMPwd yourpassword |sort PowerState |ft -AutoSize
.EXAMPLE
	Get-Content -Path "C:\reports\imm.txt" `
	|Reboot-IMMServerOS -IMMCred (Get-Credential -UserName yourlogin -Message "IMM credentials")
.EXAMPLE
	$immCol = Get-IMMSubnet "10.98.1.0" 120 150 |Reboot-IMMServerOS -IMMCred $immCred -Confirm:$false
	$immCol |sort PowerState,IMM |ft
	$immCol |? {$_.PowerState -eq 'PoweredOff'} |select IMM |ft -HideTableHeaders
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 2 Properties: IMM,PowerState.
	PowerState may be one of the two options: Rebooted,Unknown.
	The major reasons for 'Unknown' power state are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR',ConfirmImpact='High',SupportsShouldProcess=$true)]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$i = 0
}

Process {

	Foreach ($module in $IMM) {
	
		If ($PSCmdlet.ShouldProcess($IMM,"Restart OS and Reboot Server")) {
	
			$ASUCmd       = "immapp Rebootos"
			$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
			$ASUPrint     = ''
			$ASUMatch     = $null
			$regexSuccess = 'Issuing\ssystem\sreboot\scommand'
			
			$i += 1
			Write-Progress -Activity "Rebooting Server" -Status "[$i] $module"
			
			$ASUPrint = Invoke-Expression -Command $ASUCmdLine
			$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

			If ($ASUMatch.Success) {$ASUReturn = "Rebooted"} Else {$ASUReturn = "Unknown"}

			$Properties = [ordered]@{
				IMM        = $module
				PowerState = $ASUReturn
			}
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
	}

}

} #EndFunction Reboot-IMMServerOS #4

Function Restart-IMM {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function Restart IMM card itself.
.DESCRIPTION
    This function Restart IMM card itself.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Restart-IMM esxhai1r -IMMCred (Get-Credential -UserName yourlogin -Message "IMM credentials")
.EXAMPLE
	Restart-IMM -IMM "esxhai1r","esxhai2r" |sort PowerState |ft -AutoSize
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Get-Content -Path "C:\reports\imm.txt" |Restart-IMM -IMMCred $immCred
.EXAMPLE
	$immCol = Get-IMMSubnet "10.98.1.0" 120 150 |Restart-IMM -IMMCred $immCred -Confirm:$false
	$immCol |sort PowerState,IMM |ft
	$immCol |? {$_.PowerState -eq 'Restarted'} |select IMM |ft -HideTableHeaders
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 2 Properties: IMM,PowerState.
	PowerState may be one of the two options: Restarted,Unknown.
	The major reasons for 'Unknown' power state are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR',ConfirmImpact='High',SupportsShouldProcess=$true)]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$i = 0
}

Process {

	Foreach ($module in $IMM) {
	
		If ($PSCmdlet.ShouldProcess($IMM,"Restart IMM")) {
	
			$ASUCmd       = "rebootimm"
			$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
			$ASUPrint     = ''
			$ASUMatch     = $null
			$regexSuccess = 'imm\shas\sstarted\sthe\sreset'
			
			$i += 1
			Write-Progress -Activity "Restarting IMM" -Status "[$i] $module"
			
			$ASUPrint = Invoke-Expression -Command $ASUCmdLine
			$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

			If ($ASUMatch.Success) {$ASUReturn = "Restarted"} Else {$ASUReturn = "Unknown"}

			$Properties = [ordered]@{
				IMM        = $module
				PowerState = $ASUReturn
			}
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
	}

}

} #EndFunction Restart-IMM #5

Function Get-IMMInfo {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function retrives IBM server's IMM Info.
.DESCRIPTION
    This function retrives IBM server's IMM Info.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Get-IMMInfo esxhai1r
.EXAMPLE
	Get-IMMInfo -IMM "esxhai1r","esxhai2r" -IMMLogin yourlogin -IMMPwd yourpassword |sort IMM |ft -AutoSize
.EXAMPLE
	This example will show how simple to get full Class-C subnet or IP range with Get-IMMInfo & Get-IMMSubnet functions pair
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	$immSubnet = Get-IMMSubnet -Subnet "10.98.1.0" -StartIP 60 -EndIP 165 `
	|Get-IMMInfo -IMMCred $immCred
	
	$immSubnet |? {$_.DisplayName -ne $_.HostName} |sort HostName |ft -AutoSize
	$immSubnet |? {$_.HostName -ne ''} |sort HostName |Export-Csv -NoTypeInformation -Path "C:\reports\immSubnet98.csv"
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 8 Properties: IMM,DisplayName,HostName,Server,Model,Serial,Contact,Location.
	Properties may be empty.
	The major reasons for empty properties are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM or
	no DNS resolve.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$i = 0
}

Process {
	
	Foreach ($module in $IMM) {
	
		$ASUCmd       = "show --setlist IMM.IMMInfo_Name IMM.HostName1 SYSTEM_PROD_DATA.SysInfoProdIdentifier SYSTEM_PROD_DATA.SysInfoProdName SYSTEM_PROD_DATA.SysInfoSerialNum IMM.IMMInfo_Contact IMM.IMMInfo_Location"
		$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
		$ASUPrint     = ''
		$ASUMatch     = $null
		$regexSuccess = "Connected to IMM at IP address.+"

		$i += 1
		Write-Progress -Activity "Gathering IMM Info" -Status "[$i] $module"

		$ASUPrint = Invoke-Expression -Command $ASUCmdLine
		$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

		If ($ASUMatch.Success) {
			$ASUPrint = $ASUPrint[4..$ASUPrint.Count]

			$Properties = [ordered]@{
				IMM         = $module
				DisplayName = ($ASUPrint[0] -split '=')[1]
				HostName    = ($ASUPrint[1] -split '=')[1]
				Server      = ($ASUPrint[2] -split '=')[1]
				Model       = ($ASUPrint[3] -split '=')[1]
				Serial      = ($ASUPrint[4] -split '=')[1]
				Contact     = ($ASUPrint[5] -split '=')[1]
				Location    = ($ASUPrint[6] -split '=')[1]	
			}
				
		} Else {
		
			$Properties = [ordered]@{
				IMM         = $module
				DisplayName = ''
				HostName    = ''
				Server      = ''
				Model       = ''
				Serial      = ''
				Contact     = ''
				Location    = ''
			}
		}

		$Object = New-Object PSObject -Property $Properties
		$Object
	}

}

} #EndFunction Get-IMMInfo #6

Function Get-IMMSettings {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function retrives IBM server's IMM settings.
.DESCRIPTION
    This function retrives full list of IBM server's IMM settings.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Get-IMMSettings esxhai1r
.EXAMPLE
	Get-IMMSettings -IMM "10.99.1.150" -IMMLogin yourlogin -IMMPwd yourpassword |ft -AutoSize
.EXAMPLE
	Get-IMMSettings "10.99.1.150" |select Group,'Param',Value |? {$_.Group -eq 'pxe'} |ft -AutoSize
.EXAMPLE
	Get-IMMSettings "10.99.1.150" |Export-Csv -NoTypeInformation -Path 'C:\reports\immSettings.csv'
.EXAMPLE
	Get-IMMSettings "10.99.1.150" |Out-GridView -Title "IMM settings"
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 4 Properties: IMM,Group,Param,Value or $null.
	The major reasons for $null are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM or
	no DNS resolve.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}	
}

Process {

	$ASUCmd       = "show"
	$ASUCmdLine   = "$ASUExec $ASUCmd --host $IMM --user $IMMLogin --password $IMMPwd"
	$ASUPrint     = ''
	$ASUMatch     = $null
	$regexSuccess = "Connected to IMM at IP address"
	$regexLine    = '(?<Group>.+?)\.(?<Param>.+?)=(?<Value>.*)'
	$Matches      = $null

	Write-Progress -Activity "Gathering IMM Settings" -Status "$IMM"

	$ASUPrint = Invoke-Expression -Command $ASUCmdLine
	$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

	If ($ASUMatch.Success) {
	
		Foreach ($line in $ASUPrint) {
		
			$lineMatch = $line -match $regexLine
			
			If ($lineMatch) {

				$Properties = [ordered]@{
					IMM     = $IMM
					'Group' = $Matches.Group
					'Param' = $Matches.Param
					Value   = $Matches.Value
				}
				$Object = New-Object PSObject -Property $Properties
				$Object
			}
			
		}
			
	} Else {$Object = $null}

}

} #EndFunction Get-IMMSettings #7

Function Get-IMMParam {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function retrives IBM server's IMM single parameter.
.DESCRIPTION
    This function retrives IBM server's IMM single parameter from allowed parameters set.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.PARAMETER Param/Key
	Single IMM's Parameter (Time Zone or DNS for example).
.EXAMPLE
	Get-IMMParam esxhai1r
.EXAMPLE
	Get-IMMParam -IMM "esxhai1r","esxhai2r" -IMMLogin yourlogin -IMMPwd yourpassword -Param DST |sort IMM
.EXAMPLE
	This example will show how simple to get full Class-C subnet or IP range with Get-IMMParam & Get-IMMSubnet functions pair
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	$immBulk = Get-IMMSubnet -Subnet "10.98.1.0" -StartIP 60 -EndIP 165 `
	|Get-IMMParam -IMMCred $immCred -Param TimeZone
	$immBulk |? {$_.TimeZone -ne ''} |sort TimeZone,IMM |ft -AutoSize
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 3 Properties: IMM,Param,Value.
	All allowed values for '-Param' are [ValidateSet()] attribute members.
	'Value' property may be empty.
	The major reasons for empty 'Value' property are bad credentials,
	specified Login ID doesn't have supervisor rights on IMM,
	no DNS resolve or its parameter's value is realy empty/not set.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
	,
	[Parameter(
		Mandatory=$true,Position=4,
		HelpMessage = "IMM Parameter"
		)]
		[ValidateSet('DNS_IP_Address1','DNS_IP_Address2','DST','GatewayIPAddress1','HostIPAddress1', `
		'HostIPSubnet1','NTPAutoSynchronization','NTPHost','NTPHost1','TimeZone','LoginId.1','LoginId.2', `
		'AuthorityLevel.1','AuthorityLevel.2','IMMInfo_Contact','IMMInfo_Location')]
		[Alias("Key")]
	[System.String]$Param
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$i = 0
}

Process {
	
	Foreach ($module in $IMM) {
	
		$ASUCmd       = "show IMM.$Param"
		$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
		$ASUPrint     = ''
		$ASUMatch     = $null
		$regexSuccess = "Connected to IMM at IP address.+"

		$i += 1
		Write-Progress -Activity "Gathering IMM '$Param' parameter" -Status "[$i] $module"

		$ASUPrint = Invoke-Expression -Command $ASUCmdLine
		$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

		If ($ASUMatch.Success) {
			$ASUPrint = $ASUPrint[4]

			$Properties = [ordered]@{
				 IMM     = $module
				'Param'  = $Param
				 Value   = ($ASUPrint -split '=')[1]
			}
				
		} Else {
		
			$Properties = [ordered]@{
				 IMM     = $module
				'Param'  = $Param
				 Value   = ''
			}
		}

		$Object = New-Object PSObject -Property $Properties
		$Object
	}

}

} #EndFunction Get-IMMParam #8

Function Set-IMMParam {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function set IBM server's IMM single parameter.
.DESCRIPTION
    This function set IBM server's IMM single parameter from allowed parameters set.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.PARAMETER Param/Key
	Single IMM's Parameter (Time Zone or DNS for example).
.PARAMETER Value/ParamValue (optional, default is empty string)
	Single IMM Parameter's Value.
.EXAMPLE
	Set-IMMParam esxhai1r -Param TimeZone -Value "GMT+2:00"
.EXAMPLE
	Set-IMMParam -IMM "esxhai1r","esxhai2r" -IMMLogin yourlogin -IMMPwd yourpassword -Param DST -Value Yes
.EXAMPLE
	This example will show how simple to set full Class-C subnet or IP range with Set-IMMParam & Get-IMMSubnet functions pair
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	$immSet = Get-IMMSubnet "10.98.1.0" 21 |Get-IMMParam -IMMCred $immCred -Param TimeZone
	
	$immSet |? {'GMT+2:00','' -notcontains $_.TimeZone} `
	|Set-IMMParam -IMMCred $immCred -Value "GMT+2:00" -Confirm:$false `
	|Export-Csv -NoTypeInformation -Path C:\reports\SetImmTZ.csv
.EXAMPLE
	This example will set bulk of IMM settings exported from CSV file to bulk of IMM cards.
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	$immSet = Get-IMMSubnet -Subnet "10.98.1.0" |Get-IMMParam -IMMCred $immCred -Param TimeZone

	# CSV will contain 2 columns: IMMKey|IMMValue (key-value pairs)
	$immHash = Import-Csv -Path .\immSettings.csv
	Foreach ($imm in $immSet) {
		Foreach ($pair in $immHash) {
			Set-IMMParam -IMM $imm -IMMCred $immCred -Param "$($pair.IMMKey)" -Value "$($pair.IMMValue)" -Confirm:$false
		}
	}
.EXAMPLE
	$immLoginId = @()
	$immLoginId += Set-IMMParam "10.98.1.100","10.98.1.101" -Confirm:$false -Param LoginId.2 -Value yourlogin
	$immLoginId += Set-IMMParam "10.98.1.100","10.98.1.101" -Confirm:$false -Param Password.2 -Value yourpassword
	$immLoginId += Set-IMMParam "10.98.1.100","10.98.1.101" -Confirm:$false -Param AuthorityLevel.2 -Value Supervisor
	$immLoginId += Set-IMMParam "10.98.1.100","10.98.1.101" -Confirm:$false -Param AuthorityLevel.1 -Value ReadOnly
	
	$immLoginId |sort IMM,'Param' |group IMM `
	|select Count,@{Name='IMM';Expression={$_.Name}}, `
	@{Name='Values';Expression={($_ |select -ExpandProperty Group).Value}} |ft -AutoSize
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 3 Properties: IMM,Param,Value.
	All allowed values for '-Param' are [ValidateSet()] attribute members.
	'Value' property may be empty.
	The major reasons for empty 'Value' property is bad credentials,
	specified Login ID doesn't have supervisor rights on IMM,
	no DNS resolve or supplied value is not allowed for this Parameter.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR',ConfirmImpact='High',SupportsShouldProcess=$true)]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
	,
	[Parameter(
		Mandatory=$true,Position=4,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM Parameter"
		)]
		[ValidateSet('DNS_IP_Address1','DNS_IP_Address2','DST','GatewayIPAddress1', `
		'HostIPSubnet1','NTPAutoSynchronization','NTPHost','NTPHost1','TimeZone','LoginId.1','LoginId.2', `
		'AuthorityLevel.1','AuthorityLevel.2','Password.1','Password.2','IMMInfo_Name','HostName1', `
		'IMMInfo_Contact','IMMInfo_Location')]
		[Alias("Key")]
	[System.String]$Param
	,
	[Parameter(
		Mandatory=$false,Position=5,
		HelpMessage = "IMM Parameter's Value"
		)]
	[System.String]$Value = ''
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$i = 0
	
	$quote = '`"'
	If ($Value -match '^.+\s.+$') {$Value = "$quote$Value$quote"}
}

Process {
	
	Foreach ($module in $IMM) {
	
		If ($PSCmdlet.ShouldProcess($IMM,"Set parameter '$Param' to value '$Value'")) {
			
			$ASUCmd       = "set IMM.$Param $Value"
			$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
			$ASUPrint     = ''
			$ASUMatch     = $null
			$regexSuccess = "Command completed successfully"

			$i += 1
			If ($Param -notmatch 'password') {
				Write-Progress -Activity "Setting IMM '$Param' parameter to value '$Value'" -Status "[$i] $module"
			} Else {
				Write-Progress -Activity "Setting IMM '$Param' parameter" -Status "[$i] $module"
			}

			$ASUPrint = Invoke-Expression -Command $ASUCmdLine
			$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)
			
			If ($ASUMatch.Success) {
			
				$ASUPrint = $ASUPrint[4]
				
				$Properties = [ordered]@{
					 IMM    = $module
					'Param' = ($ASUPrint -split '=')[0]
					 Value  = ($ASUPrint -split '=')[1]
				}
				
			} Else {
			
				$Properties = [ordered]@{
					 IMM    = $module
					'Param' = "IMM.$Param"
					 Value  = ''
				}
			}

			$Object = New-Object PSObject -Property $Properties
			$Object
		}
	}

}

} #EndFunction Set-IMMParam #9

Function Get-IMMSystemEventLog {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function retrives IBM server's SEL.
.DESCRIPTION
    This function retrives IBM server's System Event Log.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Get-IMMSystemEventLog esxhai1r
.EXAMPLE
	Get-IMMSystemEventLog -IMM "esxhai1r","esxhai2r" -IMMLogin yourlogin -IMMPwd yourpassword |sort IMM |ft -AutoSize
.EXAMPLE
	This example will show how simple to get full Class-C subnet or IP range with Get-IMMSystemEventLog & Get-IMMSubnet functions pair
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	$immSubnet = Get-IMMSubnet -Subnet "10.98.1.0" -StartIP 60 -EndIP 165 `
	|Get-IMMSystemEventLog -IMMCred $immCred
	
	$immSubnet |? {$_.Version -ne ''} |? {$_.'Used%' -le 20 -or $_.FreeBytes -lt 1000} |sort 'Used%' -Descending |ft -AutoSize
	$immSubnet |? {$_.Version -ne ''} |? {$_.FreeBytes -eq 0} |ft -AutoSize
	$immSubnet |sort 'Used%',FreeBytes |Export-Csv -NoTypeInformation -Path "C:\reports\immSubnet98.csv"
	$immSubnet |? {$_.Version -eq ''} |select IMM |fw -Column 6
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 7 Properties: IMM,Version,Entries,FreeBytes,Used%,LastAddTime,LastDelTime.
	All properties except IMM may be empty.
	The major reasons for empty properties are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM or
	no DNS resolve.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$i = 0
}

Process {
	
	Foreach ($module in $IMM) {
	
		$ASUCmd       = "immapp Showsel"
		$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
		$ASUPrint     = ''
		$ASUMatch     = $null
		$regexSuccess = "Connected to IMM at IP address.+"

		$i += 1
		Write-Progress -Activity "Gathering SEL Info" -Status "[$i] $module"

		$ASUPrint = Invoke-Expression -Command $ASUCmdLine
		$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

		If ($ASUMatch.Success) {
			$ASUPrint = $ASUPrint[5..10]

			$Properties = [ordered]@{
				IMM         =   $module
				Version     =   ($ASUPrint[0] -split ': ')[1]
				Entries     =   ($ASUPrint[1] -split ': ')[1]
				FreeBytes   = ((($ASUPrint[2] -split ': ')[1]) -split ' ')[0]
				'Used%'     =  (($ASUPrint[3] -split ': ')[1]).TrimEnd('%')
				LastAddTime =   ($ASUPrint[4] -split ': ')[1]
				LastDelTime =   ($ASUPrint[5] -split ': ')[1]
			}
				
		} Else {
		
			$Properties = [ordered]@{
				IMM         = $module
				Version     = ''
				Entries     = ''
				FreeBytes   = ''
				'Used%'     = ''
				LastAddTime = ''
				LastDelTime = ''
			}
		}

		$Object = New-Object PSObject -Property $Properties
		$Object
	}

}

} #EndFunction Get-IMMSystemEventLog #10

Function Clear-IMMSystemEventLog {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function clear IBM server's SEL.
.DESCRIPTION
    This function clear (delete all entries) IBM server's System Event Log.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Clear-IMMSystemEventLog "10.98.1.153"
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Clear-IMMSystemEventLog -IMM "10.98.1.153","10.98.1.152" -IMMCred $immCred |sort IMM |ft -AutoSize
.EXAMPLE
	This example will show how simple to get full Class-C subnet or IP range with Clear-IMMSystemEventLog & Get-IMMSubnet functions pair
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Get-IMMSubnet -Subnet "10.98.1.0" -StartIP 60 -EndIP 165 |Clear-IMMSystemEventLog -IMMCred $immCred -Confirm:$false
	!!! Be careful with (-Confirm:$false) !!!
.EXAMPLE
	This sample clear all full SEL (FreeBytes=0) on given network without confirmation !
	
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Get-IMMSubnet "10.98.1.0" |Get-IMMSystemEventLog -IMMCred $immCred |? {$_.FreeBytes -eq 0} `
	|Clear-IMMSystemEventLog -IMMCred $immCred -Confirm:$false |ft -AutoSize
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 7 Properties: IMM,Version,Entries,FreeBytes,Used%,LastAddTime,LastDelTime.
	All properties except IMM may be empty.
	The major reasons for empty properties are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM or
	no DNS resolve.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR',ConfirmImpact='High',SupportsShouldProcess=$true)]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$i = 0
}

Process {
	
	Foreach ($module in $IMM) {
	
		If ($PSCmdlet.ShouldProcess($IMM,"Clear System Event Log")) {
		
			$ASUCmd       = "immapp Clearsel"
			$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
			$ASUPrint     = ''
			$ASUMatch     = $null
			$regexSuccess = "Successfully clear"

			$i += 1
			Write-Progress -Activity "Clearing SEL" -Status "[$i] $module"

			$ASUPrint = Invoke-Expression -Command $ASUCmdLine
			$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)
			
			If ($ASUMatch.Success) {Get-IMMSystemEventLog -IMM $module -IMMLogin $IMMLogin -IMMPwd $IMMPwd}
	
		}
	}

}

} #EndFunction Clear-IMMSystemEventLog #11

Function Get-IMMSystemEventLogEntries {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function retrives IBM server's SEL Entries.
.DESCRIPTION
    This function retrives IBM server's System Event Log Entries.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Get-IMMSystemEventLogEntries esxhai1r
.EXAMPLE
	Get-IMMSystemEventLogEntries -IMM esxhai1r -IMMLogin yourlogin -IMMPwd yourpassword |select -Last 20 |ft -AutoSize
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Get-IMMSystemEventLogEntries -IMMCred $immCred -IMM esxhai1r |sort Date,Time -Descending |select -First 10 |ft -AutoSize
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Get-IMMSystemEventLogEntries -IMMCred $immCred -IMM esxhai1r `
	|? {$_.Event -like 'system boot*'} |sort Date,Time -Descending |ft -AutoSize
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Get-IMMSystemEventLogEntries -IMMCred $immCred -IMM esxhai1r |Export-Csv -NoTypeInformation -Path "C:\reports\SEL.csv"
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 7 Properties: IMM,Num,Date,Time,Entry,Event,Assert or $null.
	The major reasons for $null are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM or
	no DNS resolve.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}	
}

Process {
	
		$ASUCmd       = "immapp Showsel"
		$ASUCmdLine   = "$ASUExec $ASUCmd --host $IMM --user $IMMLogin --password $IMMPwd"
		$ASUPrint     = ''
		$ASUMatch     = $null
		$regexSuccess = "Connected to IMM at IP address.+"

		Write-Progress -Activity "Gathering SEL Entries" -Status "$IMM"

		$ASUPrint = Invoke-Expression -Command $ASUCmdLine
		$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

		If ($ASUMatch.Success) {
			$ASUPrint = $ASUPrint[13..$ASUPrint.Count]
			
			Foreach ($line in $ASUPrint) {
			
				$line = $line -replace '^\s+', ''
				$line = $line -split '\s\|\s'

				$Properties = [ordered]@{
					IMM    = $IMM
					Num    = $line[0]
					Date   = $line[1]
					Time   = $line[2]
					Entry  = $line[3]
					Event  = $line[4]
					Assert = $line[5]
				}
				$Object = New-Object PSObject -Property $Properties
				$Object
			}
				
		} Else {$Object = $null}
}

} #EndFunction Get-IMMSystemEventLogEntries #12

Function Get-IMMSubnet {

<#
.SYNOPSIS
    Helper function.
	Get IP addresses in the subnet or IP range.
.DESCRIPTION
	Helper function, used to assist to all other functions.
	This function enumerates possible IP addresses
	within Class-C network subnet or within IP range.
.PARAMETER Subnet/Network
    Class C network subnet (must end by zero).
.PARAMETER StartIP/FirstIP (optional, default is 1)
    First IP address in range.
.PARAMETER EndIP/LastIP (optional, default is 254)
    Last IP address in range.
.EXAMPLE
	Get-IMMSubnet -Subnet "10.98.1.0" -StartIP 50 -EndIP 100
.EXAMPLE
	Get-IMMSubnet "192.168.1.0" 100 120
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	IPv4 addresses collection.
#>

Param (

	[Parameter(
		Mandatory=$true,Position=0,
		HelpMessage = "Class C network subnet"
		)]
		[ValidatePattern("^(?<A>2[0-4]\d|25[0-5]|[01]?\d\d?)\.(?<B>2[0-4]\d|25[0-5]|[01]?\d\d?)\.(?<C>2[0-4]\d|25[0-5]|[01]?\d\d?)\.(?<D>0)$")]
		[Alias("Network")]
	[System.String]$Subnet
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "First IP address in range"
		)]
		[ValidateRange(1,253)]
		[Alias("FirstIP")]
	[System.Int32]$StartIP = 1
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "Last IP address in range"
		)]
		[ValidateRange(2,254)]
		[Alias("LastIP")]
	[System.Int32]$EndIP = 254
)

Begin {

	If ($StartIP -ge $EndIP) {Throw "Last IP must be greater than First IP"}
}

Process {
	$SubnetC = $Subnet.TrimEnd('0')
	$sub = @()
	For ($i=$StartIP;$i -le $EndIP;$i++) {$sub += "$SubnetC$i"}
	$sub
}

} #EndFunction Get-IMMSubnet #13

Function Connect-IMMSSH {

<#
.SYNOPSIS
    Open SSH session to IMM with plink.exe in PoSh window.
.DESCRIPTION
    This function opens SSH session to IMM with plink.exe in the PowerShell console.
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER Plink (optional, default set by '$Plink' variable)
	Plink executable full path.
.EXAMPLE
	Connect-IMMSSH esxhai1r
.EXAMPLE
	Connect-IMMSSH esxhai1r -IMMLogin yourlogin -IMMPwd yourpassword
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Connect-IMMSSH esxhai1r $immCred
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "Plink SSH/SFTP client executable full path"
		)]
		[ValidatePattern("^plink\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("PlinkExecutable")]
	[System.String]$PlinkExec = $Plink
)

Begin {

	If (!(Test-Path -Path FileSystem::$PlinkExec)) {Throw "Plink executable '$PlinkExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
}

Process {
		
	$PlinkCmdLine = "$PlinkExec -t -pw $IMMPwd $IMMLogin@$IMM"
	Invoke-Expression -Command $PlinkCmdLine	
}

} #EndFunction Connect-IMMSSH #14

Function Get-IMMServerBootOrder {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function retrives IBM server's UEFI Boot Order.
.DESCRIPTION
    This function retrives IBM server's UEFI Boot Order.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Get-IMMServerBootOrder esxhai1r
.EXAMPLE
	Get-IMMServerBootOrder -IMM "esxhai1r","esxhai2r" -IMMLogin yourlogin -IMMPwd yourpassword |sort IMM |ft -AutoSize
.EXAMPLE
	This example will show how simple to get full Class-C subnet or IP range with Get-IMMServerBootOrder & Get-IMMSubnet functions pair
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	$immSubnet = Get-IMMSubnet -Subnet "10.98.1.0" -StartIP 60 -EndIP 165 `
	|Get-IMMServerBootOrder -IMMCred $immCred
	
	$immSubnet |? {$_.Boot1 -eq 'Hard Disk 0'} |ft -AutoSize
	$immSubnet |sort Boot1,Boot2 |Export-Csv -NoTypeInformation -Path "C:\reports\immSubnet98.csv"
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 5 Properties: IMM,Boot1,Boot2,Boot3,Boot4.
	Some properties may be empty (no boot device set at particular position).
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$i = 0
}

Process {
	
	Foreach ($module in $IMM) {
	
		$ASUCmd       = "show BootOrder.BootOrder"
		$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
		$ASUPrint     = ''
		$ASUMatch     = $null
		$regexSuccess = "Connected to IMM at IP address.+"

		$i += 1
		Write-Progress -Activity "Gathering Server Boot Order" -Status "[$i] $module"

		$ASUPrint = Invoke-Expression -Command $ASUCmdLine
		$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

		If ($ASUMatch.Success) {
		
			$bo = ($ASUPrint[4] -split '=')
			
			$Properties = [ordered]@{
				IMM   = $module
				Boot1 = $bo[1]
				Boot2 = $bo[2]
				Boot3 = $bo[3]
				Boot4 = $bo[4]
			}
				
		} Else {
		
			$Properties = [ordered]@{
				IMM   = $module
				Boot1 = ''
				Boot2 = ''
				Boot3 = ''
				Boot4 = ''
			}
		}
		
		$Object = New-Object PSObject -Property $Properties
		$Object
	}

}

} #EndFunction Get-IMMServerBootOrder #15

Function Set-IMMServerBootOrder {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function set IBM server's UEFI Boot Order.
.DESCRIPTION
    This function set IBM server's UEFI Boot Order.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.PARAMETER Boot1 (optional, default is 'CD/DVD Rom')
	First Boot Device
.PARAMETER Boot2 (optional, default is 'Floppy Disk')
	Second Boot Device
.PARAMETER Boot3 (optional, default is 'Hard Disk 0')
	Third Boot Device
.PARAMETER Boot4 (optional, default is 'PXE Network')
	Fourth Boot Device
.EXAMPLE
	Set-IMMServerBootOrder esxhai1r
.EXAMPLE
	Set-IMMServerBootOrder -IMM "esxhai1r","esxhai2r" -IMMLogin yourlogin -IMMPwd yourpassword `
	-Boot2 "CD/DVD Rom" -Boot1 "Hard Disk 0" |sort IMM |ft -AutoSize
.EXAMPLE
	This example will show how simple to set Boot Order for full Class-C subnet with Set-IMMServerBootOrder & Get-IMMSubnet functions pair
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	$immSubnet = Get-IMMSubnet -Subnet "10.98.1.0" -StartIP 60 -EndIP 165 `
	|Set-IMMServerBootOrder -IMMCred $immCred
	
	$immSubnet |? {$_.Boot1 -eq 'Hard Disk 0'} |ft -AutoSize
	$immSubnet |sort Boot1,Boot2 |Export-Csv -NoTypeInformation -Path "C:\reports\immSubnet98.csv"
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 5 Properties: IMM,Boot1,Boot2,Boot3,Boot4.
	Properties may be empty.
	If all properties except IMM are empty, setting Boot Order didn't successfull,
	also you will see something like this:
	"CD/DVD Rom=CD/DVD Rom=Hard Disk 0=PXE Network" is not a valid value for setting BootOrder.BootOrder
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR',ConfirmImpact='High',SupportsShouldProcess=$true)]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
	,
	[Parameter(
		Mandatory=$false,Position=4,
		HelpMessage = "First boot device"
		)]
		[ValidateSet('CD/DVD Rom','Floppy Disk','Hard Disk 0','PXE Network','VDIESXi5.5','ESXi5VDI')]
	[System.String]$Boot1 = 'CD/DVD Rom'
	,
	[Parameter(
		Mandatory=$false,Position=5,
		HelpMessage = "Second boot device"
		)]
		[ValidateSet('CD/DVD Rom','Floppy Disk','Hard Disk 0','PXE Network','VDIESXi5.5','ESXi5VDI')]
	[System.String]$Boot2 = 'Floppy Disk'
	,
	[Parameter(
		Mandatory=$false,Position=6,
		HelpMessage = "Third boot device"
		)]
		[ValidateSet('CD/DVD Rom','Floppy Disk','Hard Disk 0','PXE Network','VDIESXi5.5','ESXi5VDI')]
	[System.String]$Boot3 = 'Hard Disk 0'
	,
	[Parameter(
		Mandatory=$false,Position=7,
		HelpMessage = "Fourth boot device"
		)]
		[ValidateSet('CD/DVD Rom','Floppy Disk','Hard Disk 0','PXE Network','VDIESXi5.5','ESXi5VDI','')]
	[System.String]$Boot4 = 'PXE Network'
	
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	$quote = '`"'
	$sign  = '='
	If ($Boot1 -match '^.+\s.+$') {$bdev1 = "$quote$Boot1$quote"} Else {$bdev1 = $Boot1}
	If ($Boot2 -match '^.+\s.+$') {$bdev2 = "$quote$Boot2$quote"} Else {$bdev2 = $Boot2}
	If ($Boot3 -match '^.+\s.+$') {$bdev3 = "$quote$Boot3$quote"} Else {$bdev3 = $Boot3}
	If ($Boot4 -match '^.+\s.+$') {$bdev4 = "$quote$Boot4$quote"} Else {$bdev4 = $Boot4}
	
	$i = 0
}

Process {
	
	Foreach ($module in $IMM) {
	
		If ($PSCmdlet.ShouldProcess($IMM,"Change Server Boot Order")) {
		
			$ASUCmd       = "set BootOrder.BootOrder $bdev1$sign$bdev2$sign$bdev3$sign$bdev4"
			$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
			$ASUPrint     = ''
			$ASUMatch     = $null
			$regexSuccess = ".+Command completed successfully.*"

			$i += 1
			Write-Progress -Activity "Setting Server Boot Order" -Status "[$i] $module"

			$ASUPrint = Invoke-Expression -Command $ASUCmdLine
			$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

			If ($ASUMatch.Success) {
			
				$bo = ($ASUPrint[4] -split '=')
				
				$Properties = [ordered]@{
					IMM   = $module
					Boot1 = $bo[1]
					Boot2 = $bo[2]
					Boot3 = $bo[3]
					Boot4 = $bo[4]
				}
					
			} Else {
			
				$Properties = [ordered]@{
					IMM   = $module
					Boot1 = ''
					Boot2 = ''
					Boot3 = ''
					Boot4 = ''
				}
			}
			
			$Object = New-Object PSObject -Property $Properties
			$Object
		}
	}

}

} #EndFunction Set-IMMServerBootOrder #16

Function Mount-IMMISO {

<#
.SYNOPSIS
    IBM Remote Disk CLI (rdmount.exe) Powershell skin.
	Mount ISO file to IBM server via IMM.
.DESCRIPTION
	This function mount ISO file to IBM server's Virtual Media Drive.
	On IMM2 requires IBM FoD "Advanced Upgrade" license key!
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER RDMExec/RDMExecutable (optional, default set by '$RDM' variable)
	IBM Remote Disk CLI executable full path.
.PARAMETER ISO/MountISO
	ISO file full path.
.EXAMPLE
	Mount-IMMISO esxhai1r -ISO C:\ISO\Office_Professional_Plus_2013_64Bit_English.ISO
.EXAMPLE
	Mount-IMMISO -IMM esxhai1r -IMMLogin yourlogin -IMMPwd yourpassword -ISO C:\ISO\Office_Professional_Plus_2013_64Bit_English.ISO
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Mount-IMMISO -IMM esxhai1r -IMMCred $immCred -ISO C:\ISO\Office_Professional_Plus_2013_64Bit_English.ISO
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	PSObject with 2 Properties: IMM,ISO.
	'ISO' property may be empty.
	The major reasons for empty 'ISO' property are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM or
	no DNS resolve or no FoD license key activated.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM RDCLI executable full path"
		)]
		[ValidatePattern("^rdmount\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("RDMExecutable")]
	[System.String]$RDMExec = $RDM
	,
	[Parameter(
		Mandatory=$true,Position=4,
		HelpMessage = "ISO file to mount"
		)]
		[ValidatePattern("^.+\.iso$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("MountISO")]
	[System.String]$ISO

)

Begin {

	If (!(Test-Path -Path FileSystem::$RDMExec)) {Throw "RDCLI executable '$RDMExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
}

Process {
	
	$RDMArgs        = "-s $IMM -l $IMMLogin -p $IMMPwd -d $ISO"
	$RDQueryCmdLine = "$RDMExec -s $IMM -q"
	$RDMPrint       = ''
	$RDMMatch       = $null
	$regexSuccess   = 'Token.*\d+'
	$RDMProc        = $null
	
	$RDMPrint = Invoke-Expression -Command $RDQueryCmdLine
	$RDMMatch = [regex]::match($RDMPrint, $regexSuccess)

	If ($RDMMatch.Success) {
		Throw "Error mounting ISO, please UNmount first"
	
	} Else {
	
		$RDMProc = Start-Process $RDMExec -ArgumentList $RDMArgs -Wait:$false -PassThru
		Start-Sleep -Seconds 20

		If ($RDMProc.ExitCode -eq 0) {
		
			$Properties = [ordered]@{
					IMM = $IMM
					ISO = $ISO
			}
				
		} Else {
		
			$Properties = [ordered]@{
					IMM = $IMM
					ISO = ''
			}
		}
		
		$Object = New-Object PSObject -Property $Properties
		$Object
	}
}

} #EndFunction Mount-IMMISO #17

Function Get-IMMISO {

<#
.SYNOPSIS
    IBM Remote Disk CLI (rdmount.exe) Powershell skin.
	Query is ISO file mounted to IBM server via IMM.
.DESCRIPTION
	This function query is ISO file mounted to IBM server's Virtual Media Drive.
	On IMM2 requires IBM FoD "Advanced Upgrade" license key!
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER RDMExec/RDMExecutable (optional, default set by '$RDM' variable)
	IBM Remote Disk CLI executable full path.
.EXAMPLE
	Get-IMMISO esxhai1r
.EXAMPLE
	Get-IMMISO -IMM esxhai1r -IMMLogin yourlogin -IMMPwd yourpassword
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	If (Get-IMMISO -IMM esxhai30r -IMMCred $immCred) {Unmount-IMMISO -IMM esxhai30r -IMMCred $immCred}
	Else {$immIso = Mount-IMMISO -IMM esxhai30r -IMMCred $immCred -ISO .\SQL_Svr_Standard_Edtn_2014_64Bit_English.ISO}
	If ($immIso.ISO -ne '') {"Successfully mounted"}
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	'True' if some ISO mounted to Virtual Media Drive.
	'False' in all other cases: no media mounted, connection failed and so on.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM RDCLI executable full path"
		)]
		[ValidatePattern("^rdmount\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("RDMExecutable")]
	[System.String]$RDMExec = $RDM
)

Begin {

	If (!(Test-Path -Path FileSystem::$RDMExec)) {Throw "RDCLI executable '$RDMExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
}

Process {
	
	$RDQueryCmdLine = "$RDMExec -s $IMM -q"
	$RDMPrint       = ''
	$RDMMatch       = $null
	$regexSuccess   = 'Token\s\d+\smounted'
	
	$RDMPrint = Invoke-Expression -Command $RDQueryCmdLine
	$RDMMatch = [regex]::match($RDMPrint, $regexSuccess)

	If ($RDMMatch.Success) {$true} Else {$false}
}

} #EndFunction Get-IMMISO #18

Function Unmount-IMMISO {

<#
.SYNOPSIS
    IBM Remote Disk CLI (rdumount.exe) Powershell skin.
	Unmount ISO file from IBM server via IMM.
.DESCRIPTION
	This function unmount ISO file from IBM server's Virtual Media Drive via IMM.
	On IMM2 requires IBM FoD "Advanced Upgrade" license key!
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER RDUExec/RDUExecutable (optional, default set by '$RDU' variable)
	IBM Remote Disk CLI executable full path.
.EXAMPLE
	Unmount-IMMISO esxhai1r
.EXAMPLE
	Unmount-IMMISO -IMM esxhai1r
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	'True' if some ISO unmounted.
	'False' in all other cases: no unmount operation has been performed, connection failed and so on.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IBM RDCLI executable full path"
		)]
		[ValidatePattern("^rdumount\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("RDUExecutable")]
	[System.String]$RDUExec = $RDU
)

Begin {

	If (!(Test-Path -Path FileSystem::$RDUExec)) {Throw "RDCLI executable '$RDUExec' not found"}
}

Process {
	
	$RDUCmdLine   = "$RDUExec -s $IMM"
	$RDUPrint     = ''
	$RDUMatch     = $null
	$regexSuccess = 'Umount\s+successful'
	
	$RDUPrint = Invoke-Expression -Command $RDUCmdLine
	$RDUMatch = [regex]::match($RDUPrint, $regexSuccess)

	If ($RDUMatch.Success) {$true} Else {$false}
	
}

} #EndFunction Unmount-IMMISO #19

Function Get-IMM2FoDKeys {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function retrives IBM server's Feature-on-Demand Keys.
.DESCRIPTION
    This function retrives IBM server's Feature-on-Demand (FoD) License Keys.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.EXAMPLE
	Get-IMM2FoDKeys "10.99.1.136"
.EXAMPLE
	Get-IMM2FoDKeys -IMM "10.99.1.136" -IMMLogin yourlogin -IMMPwd yourpassword |fl
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Get-IMM2FoDKeys '10.99.1.136','10.99.1.137','10.98.1.198' -IMMCred $immCred |sort IMM,Num |ft -AutoSize
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Get-IMM2FoDKeys '10.99.1.136','10.99.1.137','10.98.1.198' -IMMCred $immCred |sort IMM,Num `
	|? {$_.LicensedFoD -like '*advanced*'} |ft -AutoSize
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Get-IMM2FoDKeys '10.99.1.136','10.99.1.137','10.98.1.198' -IMMCred $immCred |sort IMM,Num `
	|Export-Csv -NoTypeInformation -Path "C:\reports\FoD.csv"
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	Collection of PSObjects with 7 Properties: IMM,Num,KeyID,Status,LicensedFoD,RemindUser,ExpiredDate or $null.
	The major reasons for $null are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM or
	no DNS resolve or IMM version 1.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR')]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String[]]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	$i = 0
}

Process {

	Foreach ($module in $IMM) {
	
		$ASUCmd       = "fodcfg reportkey"
		$ASUCmdLine   = "$ASUExec $ASUCmd --host $module --user $IMMLogin --password $IMMPwd"
		$ASUPrint     = ''
		$ASUMatch     = $null
		$regexSuccess = "Connected to CIMOM"
		$regexLine    = '^(?<Num>\d+)\s{2,}(?<KeyID>.+)\s{2,}(?<Status>\w+)\s{2,}(?<LicensedFoD>.+?)\s{2,}(?<RemindUser>.+?)\s{2,}(?<ExpiredDate>.+)'

		$i += 1
		Write-Progress -Activity "Gathering FoD License Keys" -Status "[$i] $module"

		$ASUPrint = Invoke-Expression -Command $ASUCmdLine
		$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)

		If ($ASUMatch.Success) {
			
			Foreach ($line in $ASUPrint) {
			
				$lineMatch = $line -match $regexLine
				
				If ($lineMatch) {

					$Properties = [ordered]@{
						IMM          = $module
						Num          = $Matches.Num
						KeyID        = $Matches.KeyID
						Status       = $Matches.Status
						LicensedFoD  = $Matches.LicensedFoD
						RemindUser   = $Matches.RemindUser
						ExpiredDate  = $Matches.ExpiredDate
					}
					$Object = New-Object PSObject -Property $Properties
					$Object
				}
				
			}
				
		} Else {$Object = $null}
	}	
}

} #EndFunction Get-IMM2FoDKeys #20

Function Add-IMM2FoDKey {

<#
.SYNOPSIS
    IBM Advanced Settings Utility (asu.exe/asu64.exe) Powershell skin.
	This function installs IBM server's Feature-on-Demand Key.
.DESCRIPTION
    This function install IBM server's Feature-on-Demand (FoD) License Key.
	Function outputs PoSh-objects with Properties that may be filtered by Where-Object Cmdlet,
	sorted by Sort-Object and formatted by Select-Object,ft,fl,fw (please see Examples).
.PARAMETER IMM/IMMHost/IMMIP
    IMM DNS name or IP address.
.PARAMETER IMMLogin (optional, if ommited used IBM default 'USERID')
    IMM Supervisor Login ID.
.PARAMETER IMMPwd (optional, if ommited used IBM default 'PASSW0RD')
	IMM Supervisor Login ID Password.
.PARAMETER IMMCred (Get-Credential Cmdlet object)
	IMM Supervisor Credentials.
.PARAMETER ASUExec/ASUExecutable (optional, default set by '$ASU' variable)
	IBM ASU executable full path.
.PARAMETER LicenseKey/Key
	IMM2 Fod License Key file
.EXAMPLE
	Add-IMM2FoDKey "10.99.1.136" -LicenseKey 'C:\FoD\ibm_fod_0001_7915KD6A3V7_anyos_noarch.key'
.EXAMPLE
	Add-IMM2FoDKey -IMM '10.99.1.136' -Key 'C:\FoD\ibm_fod_0001_7915KD6A3V7_anyos_noarch.key' -Confirm:$false
.EXAMPLE
	$immCred = Get-Credential -UserName yourlogin -Message "IMM credentials"
	Add-IMM2FoDKey "10.99.1.136" -IMMCred $immCred -Key 'C:\FoD\ibm_fod_0001_7915KD6A3V7_anyos_noarch.key' |ft -AutoSize
.NOTES
	Author: Roman Gelman
.LINK
	https://github.com/rgel/PowerShell/IMM-Module
.OUTPUTS
	All currently installed keys.
	Collection of PSObjects with 7 Properties: IMM,Num,KeyID,Status,LicensedFoD,RemindUser,ExpiredDate or $null.
	The major reasons for $null are bad credentials or
	specified Login ID doesn't have supervisor rights on IMM or
	no DNS resolve or IMM version 1.
#>

[CmdletBinding(DefaultParameterSetName='USERPWDPAIR',ConfirmImpact='High',SupportsShouldProcess=$true)]

Param (

	[Parameter(
		Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
		HelpMessage = "IMM DNS name or IP address"
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMHost")]
		[Alias("IMMIP")]
	[System.String]$IMM
	,
	[Parameter(
		Mandatory=$false,Position=1,
		HelpMessage = "IMM Supervisor Login ID",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMUser")]
	[System.String]$IMMLogin = "USERID"
	,
	[Parameter(
		Mandatory=$false,Position=2,
		HelpMessage = "IMM Supervisor Login ID Password",
		ParameterSetName='USERPWDPAIR'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("IMMPassword")]
	[System.String]$IMMPwd = "PASSW0RD"
	,
	[Parameter(
		Mandatory=$true,Position=1,
		HelpMessage = "IMM Supervisor Credentials",
		ParameterSetName='CREDOBJ'
		)]
		[ValidateNotNullorEmpty()]
		[Alias("Credentials")]
	[System.Management.Automation.PSCredential]$IMMCred
	,
	[Parameter(
		Mandatory=$false,Position=3,
		HelpMessage = "IBM ASU executable full path"
		)]
		[ValidatePattern("^asu\d*\.exe$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("ASUExecutable")]
	[System.String]$ASUExec = $ASU
	,
	[Parameter(
		Mandatory=$true,Position=4,
		HelpMessage = "IMM2 Feature-on-Demand License Key"
		)]
		[ValidatePattern("^.+\.key$")]
		[ValidateScript({Test-Path -Path FileSystem::$_ -PathType Leaf})]
		[Alias("Key")]
	[System.String]$LicenseKey
)

Begin {

	If (!(Test-Path -Path FileSystem::$ASUExec)) {Throw "ASU executable '$ASUExec' not found"}
	If ($IMMCred) {
		$IMMLogin = $IMMCred.GetNetworkCredential().UserName
		$IMMPwd   = $IMMCred.GetNetworkCredential().Password
	}
	
	Switch -regex ($LicenseKey) {
	
		'\\ibm_fod_0001' {$fodType = 'Advanced'; Break}
		'\\ibm_fod_0004' {$fodType = 'Standard'; Break}
		Default          {$fodType = 'Unknown' ; Break}
	
	}
	
}

Process {
	
	If ($PSCmdlet.ShouldProcess($IMM,"Install IMM '$fodType' FoD License Key from file '$LicenseKey'")) {
		
		$ASUCmd       = "fodcfg installkey -f $LicenseKey"
		$ASUCmdLine   = "$ASUExec $ASUCmd --host $IMM --user $IMMLogin --password $IMMPwd"
		$ASUPrint     = ''
		$ASUMatch     = $null
		$regexSuccess = "Succeeded installing key"

		Write-Progress -Activity "Installing '$fodType' IMM2 FoD License Key '$LicenseKey'" -Status "$IMM"

		$ASUPrint = Invoke-Expression -Command $ASUCmdLine
		$ASUMatch = [regex]::match($ASUPrint, $regexSuccess)
		
		If ($ASUMatch.Success) {Get-IMM2FoDKeys -IMM $IMM -IMMLogin $IMMLogin -IMMPwd $IMMPwd}
		Else {$null}
	}
}

} #EndFunction Add-IMM2FoDKey #21
