#requires -version 3.0

<#
.SYNOPSIS
    "Netstat.exe" regex parser.
.DESCRIPTION
    This script will get the output of 'netstat -aon' or 'netstat -ao' and parse the output.
	In addition the function will translate ProcessId to ProcessName and ProcessPath
.PARAMETER Resolve
	Resolve IP and known Port names (optional, default 'do not resolve')
.EXAMPLE
	PS> Get-NetStat |sort ProcessName |ft -au
.EXAMPLE
	PS> Get-NetStat |Out-GridView -Title Netstat
.EXAMPLE
	PS> Get-NetStat -Resolve |? {$_.State -eq 'LISTENING'} |Export-Csv -NoTypeInformation 'C:\reports\Netstat.csv'
.EXAMPLE
	PS> Get-NetStat |sort ForeignIP |group ForeignIP |select Count,Name |sort Count -Descending |ft -AutoSize -HideTableHeaders
.NOTES
	Editor:        Roman Gelman.
	Original idea: Francois-Xavier Cat (http://www.lazywinadmin.com/).
	Note that option '-Resolve' slows down the function in five to seven times !
	Compare by yourself:
	Measure-Command ({Get-NetStat}) |select Seconds |fl
	Measure-Command ({Get-NetStat -Resolve}) |select Seconds |fl
.LINK
	http://www.lazywinadmin.com/2014/08/powershell-parse-this-netstatexe.html
#>

Param (

	[Parameter(Mandatory=$false,Position=1,HelpMessage="Resolve IP and known Port names")]
	[Switch]$Resolve
)

Begin {
	$regexLine = '^\s+(?<Proto>\w+)\s{2,}(?<LocIP>.+):(?<LocPort>.+?)\s{2,}(?<DestIP>.+):(?<DestPort>.+?)\s{2,}(?<State>.+?)\s{2,}(?<PID>\d+)'
	If ($Resolve) {$cliParam = '-ao'} Else {$cliParam = '-aon'}
}

Process {

    $data = netstat $cliParam
    
    Foreach ($line in $data) {
	
		$lineMatch = $line -match $regexLine
					
		If ($lineMatch) {
	  
	        $Properties = [ordered]@{
	            Protocol    = $Matches.Proto
	            LocalIP     = $Matches.LocIP
	            LocalPort   = $Matches.LocPort
	            ForeignIP   = $Matches.DestIP
	            ForeignPort = $Matches.DestPort
	            State       = $Matches.State
				PID         = $Matches.PID
				ProcessName = Get-Process -Id ($Matches.PID) |select -ExpandProperty ProcessName
				ProcessPath = Get-Process -Id ($Matches.PID) |select -ExpandProperty Path
	        }
	    	New-Object -TypeName PSObject -Property $Properties
		}
    }
}
