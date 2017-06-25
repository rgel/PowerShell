Filter Get-OUPath {
	
<#
.SYNOPSIS
	Convert AD object's 'DistinguishedName' property to path-like format.
.DESCRIPTION
	This filter convert Active Directory object's 'DistinguishedName' property to path-like format.
	Active Directory hierarchy view like this: 'Domainname\TopLevelOU\North\HR' or without domain name 'TopLevelOU\North\HR'.
.PARAMETER IncludeDomainName
	If ommited doesn't include Domain Name to the path.
	Useful in multi domain forests.
.PARAMETER ExcludeObjectName
	If ommited include object name in the path.
.PARAMETER UCaseDomainName
	Convert Domain Name to UPPERCASE, otherwise only the capital letter is uppercased.
	contoso -> CONTOSO -> Contoso.
	Does nothing if 'IncludeDomainName' ommited.
.EXAMPLE
	PS C:\> Get-ADUser user1 |Get-OUPath
.EXAMPLE
	PS C:\> Get-ADUser -Filter {SamAccountName -like 'user*'} |select Name,@{N='OUPath';E={$_.DistinguishedName |Get-OUPath}}
	Add calculated property 'OUPath' to existing objects.
	This technique will work with all types of objects (users/computers/groups/OU etc).
.EXAMPLE
	PS C:\> Get-ADGroup -Filter {SamAccountName -like 'hr*'} |select Name,@{N='OUPath';E={$_.DistinguishedName |Get-OUPath -IncludeDomainName}} |ft -au
.EXAMPLE
	PS C:\> Get-ADGroupMember HR |select Name,@{N='OUPath';E={$_.DistinguishedName |Get-OUPath}} |sort OUPath,Name |ft -au
.EXAMPLE
	PS C:\> Get-ADOrganizationalUnit -Filter {Name -like 'North*'} |select @{N='DN';E={$_}},@{N='OUPath';E={$_ |Get-OUPath -IncludeDomainName}} |sort DN
.EXAMPLE
	PS C:\> $DNs = @()
	PS C:\> $DNs += 'CN=User1,OU=HR,OU=Northwest,OU=North,DC=contoso,DC=co,DC=il'
	PS C:\> $DNs += 'CN=User2,CN=Users,DC=contoso,DC=co,DC=il'
	PS C:\> $DNs += 'CN=Server1,CN=Computers,DC=contoso,DC=co,DC=il'
	PS C:\> $DNs += 'OU=Northwest,OU=north,DC=contoso,DC=co,DC=il'
	PS C:\> $DNs += 'OU=TopLevelOU,DC=contoso,DC=co,DC=il'
	PS C:\> $DNs |select @{N='DN';E={$_}},@{N='OUPath';E={$_ |Get-OUPath -IncludeDomainName}}
	These DNs for the different AD object types: User, User in the default 'Users' container, Computer, OU and top level OU.
.EXAMPLE
	PS C:\> Get-ADDomainController -Filter * |Get-OUPath -IncludeDomainName
.INPUTS
	[Microsoft.ActiveDirectory.Management.ADUser[]]               Active Directory user objects, returned by Get-ADUser cmdlet.
	[Microsoft.ActiveDirectory.Management.ADGroup[]]              Active Directory group objects, returned by Get-ADGroup cmdlet.
	[Microsoft.ActiveDirectory.Management.ADPrincipal[]]          Active Directory objects, returned by Get-ADGroupMember cmdlet.
	[Microsoft.ActiveDirectory.Management.ADComputer[]]           Active Directory computer objects, returned by Get-ADComputer cmdlet.
	[Microsoft.ActiveDirectory.Management.ADDomainController[]]   Active Directory DC objects, returned by Get-ADDomainController cmdlet.
	[Microsoft.ActiveDirectory.Management.ADObject[]]             Active Directory objects, returned by Get-ADObject cmdlet.
	[Microsoft.ActiveDirectory.Management.ADOrganizationalUnit[]] Active Directory OU objects, returned by Get-ADOrganizationalUnit cmdlet.
	[System.String[]]                                             Strings that represent any object's 'DistinguishedName' property.
	Or any object that have 'DistinguishedName' property.
.OUTPUTS
	[System.String[]]
	If you use '-ExcludeObjectName' switch without '-IncludeDomainName'
	both the object itself and a domain name are not included in the returned string
	and you will get EMPTY path for TOP LEVEL OU containers.
.NOTES
	Author      :: Roman Gelman.
	Version 1.0 :: 18-May-2016 :: Release :: This function was fully rewrited from the original 'Get-OUTree'.
.LINK
	http://www.ps1code.com/single-post/2016/05/20/How-to-convert-AD-objects%E2%80%99-DistinguishedName-property-to-path-like-format
#>
	
	Param ([switch]$IncludeDomainName,
		[switch]$ExcludeObjectName,
		[switch]$UCaseDomainName)
	
	If ($_.GetType().Name -eq 'string') { $DN = $_ }
	ElseIf ($_.GetType().Name -eq 'ADDomainController') { $DN = $_.ComputerObjectDN }
	Else { $DN = $_.DistinguishedName }
	
	If ($IncludeDomainName)
	{
		If ($ExcludeObjectName)
		{
			### Top level OU ###
			If (($DN -split ',')[1].ToLower().StartsWith('dc=')) { $rgxDN2OU = '(?i)^(cn|ou)=.+?,(?<OUPath>dc=.+?),' }
			### Non top level OU ###
			Else { $rgxDN2OU = '(?i)^(cn|ou)=.+?,(?<OUPath>(ou=.+?|cn=.+?),dc=.+?),' }
		}
		Else
		{
			$rgxDN2OU = '(?i)^(?<OUPath>(ou=.+?|cn=.+?),dc=.+?),'
		}
	}
	Else
	{
		If ($ExcludeObjectName) { $rgxDN2OU = '(?i)^(cn|ou)=.+?,(?<OUPath>ou=.+?|cn=.+?),dc=' }
		Else { $rgxDN2OU = '(?i)^(?<OUPath>ou=.+?|cn=.+?),dc=' }
	}
	
	Try
	{
		$arrOU = [regex]::Match($DN, $rgxDN2OU).Groups['OUPath'].Value -replace ('ou=|cn=|dc=', $null) -split (',')
		[array]::Reverse($arrOU)
		If ($IncludeDomainName)
		{
			If ($UCaseDomainName) { $Domain = $arrOU[0].ToUpper() }
			Else { $Domain = (Get-Culture).TextInfo.ToTitleCase($arrOU[0]) }
			If ($arrOU.Length -gt 1) { return $Domain + '\' + ($arrOU[1 .. ($arrOU.Length - 1)] -join ('\')) }
			Else { return $Domain }
		}
		Else { return $arrOU -join ('\') }
	}
	Catch
	{ return $null }
	
} #EndFilter Get-OUPath

Function Write-Menu
{
	
<#
.SYNOPSIS
	Display custom menu in the PowerShell console.
.DESCRIPTION
	The Write-Menu cmdlet creates numbered and colored menues
	in the PS console window and returns the choiced entry.
.PARAMETER Menu
	Menu entries.
.PARAMETER PropertyToShow
	If your menu entries are objects and not the strings
	this is property to show as entry.
.PARAMETER Prompt
	User prompt at the end of the menu.
.PARAMETER Header
	Menu title (optional).
.PARAMETER Shift
	Quantity of <TAB> keys to shift the menu items right.
.PARAMETER TextColor
	Menu text color.
.PARAMETER HeaderColor
	Menu title color.
.PARAMETER AddExit
	Add 'Exit' as very last entry.
.EXAMPLE
	PS C:\> Write-Menu -Menu "Open","Close","Save" -AddExit -Shift 1
	Simple manual menu with 'Exit' entry and 'one-tab' shift.
.EXAMPLE
	PS C:\> Write-Menu -Menu (Get-ChildItem 'C:\Windows\') -Header "`t`t-- File list --`n" -Prompt 'Select any file'
	Folder content dynamic menu with the header and custom prompt.
.EXAMPLE
	PS C:\> Write-Menu -Menu (Get-Service) -Header ":: Services list ::`n" -Prompt 'Select any service' -PropertyToShow DisplayName
	Display local services menu with custom property 'DisplayName'.
.EXAMPLE
	PS C:\> Write-Menu -Menu (Get-Process |select *) -PropertyToShow ProcessName |fl
	Display full info about choicen process.
.INPUTS
	Any type of data (object(s), string(s), number(s), etc).
.OUTPUTS
	[The same type as input object] Single menu item.
.NOTES
	Author      :: Roman Gelman @rgelman75
	Version 1.0 :: 21-Apr-2016 :: [Release]
	Version 1.1 :: 03-Nov-2016 :: [Change] Supports a single item as menu entry
	Version 1.2 :: 22-Jun-2017 :: [Change] Throw an error if property, specified by -PropertyToShow does not exist. Code optimization
.LINK
	https://ps1code.com/2016/04/21/write-menu-powershell
#>
	
	[CmdletBinding()]
	[Alias("menu")]
	Param (
		[Parameter(Mandatory, Position = 0)]
		[Alias("MenuEntry", "List")]
		$Menu
		 ,
		[Parameter(Mandatory = $false, Position = 1)]
		[string]$PropertyToShow = 'Name'
		 ,
		[Parameter(Mandatory = $false, Position = 2)]
		[ValidateNotNullorEmpty()]
		[string]$Prompt = 'Pick a choice'
		 ,
		[Parameter(Mandatory = $false, Position = 3)]
		[Alias("Title")]
		[string]$Header = ''
		 ,
		[Parameter(Mandatory = $false, Position = 4)]
		[ValidateRange(0, 5)]
		[Alias("Tab", "MenuShift")]
		[int]$Shift = 0
		 ,
		[Parameter(Mandatory = $false, Position = 5)]
		[Alias("Color", "MenuColor")]
		[System.ConsoleColor]$TextColor = 'White'
		 ,
		[Parameter(Mandatory = $false, Position = 6)]
		[System.ConsoleColor]$HeaderColor = 'Yellow'
		 ,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[Alias("Exit", "AllowExit")]
		[switch]$AddExit
	)
	
	Begin
	{
		$ErrorActionPreference = 'Stop'
		if ($Menu -isnot [array]) { $Menu = @($Menu) }
		if ($Menu[0] -isnot [string])
		{
			if (!($Menu | Get-Member -MemberType Property, NoteProperty -Name $PropertyToShow)) { Throw "Property [$PropertyToShow] does not exist" }
		}
		$MaxLength = if ($AddExit) { 8 }
		else { 9 }
		$AddZero = if ($Menu.Length -gt $MaxLength) { $true }
		else { $false }
		[hashtable]$htMenu = @{ }
	}
	Process
	{
		### Write menu header ###
		if ($Header -ne '') { Write-Host $Header -ForegroundColor $HeaderColor }
		
		### Create shift prefix ###
		if ($Shift -gt 0) { $Prefix = [string]"`t" * $Shift }
		
		### Build menu hash table ###
		for ($i = 1; $i -le $Menu.Length; $i++)
		{
			$Key = if ($AddZero)
			{
				$lz = if ($AddExit) { ([string]($Menu.Length + 1)).Length - ([string]$i).Length }
				else { ([string]$Menu.Length).Length - ([string]$i).Length }
				"0" * $lz + "$i"
			}
			else
			{
				"$i"
			}
			
			$htMenu.Add($Key, $Menu[$i - 1])
			
			if ($Menu[$i] -isnot 'string' -and ($Menu[$i - 1].$PropertyToShow))
			{
				Write-Host "$Prefix[$Key] $($Menu[$i - 1].$PropertyToShow)" -ForegroundColor $TextColor
			}
			else
			{
				Write-Host "$Prefix[$Key] $($Menu[$i - 1])" -ForegroundColor $TextColor
			}
		}
		
		### Add 'Exit' row ###
		if ($AddExit)
		{
			[string]$Key = $Menu.Length + 1
			$htMenu.Add($Key, "Exit")
			Write-Host "$Prefix[$Key] Exit" -ForegroundColor $TextColor
		}
		
		### Pick a choice ###
		Do
		{
			$Choice = Read-Host -Prompt $Prompt
			$KeyChoice = if ($AddZero)
			{
				$lz = if ($AddExit) { ([string]($Menu.Length + 1)).Length - $Choice.Length }
				else { ([string]$Menu.Length).Length - $Choice.Length }
				if ($lz -gt 0) { "0" * $lz + "$Choice" }
				else { $Choice }
			}
			else
			{
				$Choice
			}
		}
		Until ($htMenu.ContainsKey($KeyChoice))
	}
	End
	{
		return $htMenu.get_Item($KeyChoice)
	}
	
} #EndFunction Write-Menu

Function New-PercentageBar
{
	
<#
.SYNOPSIS
	Create percentage bar.
.DESCRIPTION
	This cmdlet creates percentage bar.
.PARAMETER Percent
	Value in percents (%).
.PARAMETER Value
	Value in arbitrary units.
.PARAMETER MaxValue
	100% value.
.PARAMETER BarLength
	Bar length in chars.
.PARAMETER BarView
	Different char sets to build the bar.
.PARAMETER GreenBorder
	Percent value to change bar color from green to yellow (relevant with -DrawBar parameter only).
.PARAMETER YellowBorder
	Percent value to change bar color from yellow to red (relevant with -DrawBar parameter only).
.PARAMETER NoPercent
	Exclude percentage number from the bar.
.PARAMETER DrawBar
	Directly draw the colored bar onto the PowerShell console (unsuitable for calculated properties).
.EXAMPLE
	PS C:\> New-PercentageBar -Percent 90 -DrawBar
	Draw single bar with all default settings.
.EXAMPLE
	PS C:\> New-PercentageBar -Percent 95 -DrawBar -GreenBorder 70 -YellowBorder 90
	Draw the bar and move the both color change borders.
.EXAMPLE
	PS C:\> 85 |New-PercentageBar -DrawBar -NoPercent
	Pipeline the percent value to the function and exclude percent number from the bar.
.EXAMPLE
	PS C:\> For ($i=0; $i -le 100; $i+=10) {New-PercentageBar -Percent $i -DrawBar -Length 100 -BarView AdvancedThin2; "`r"}
	Demonstrates advanced bar view with custom bar length and different percent values.
.EXAMPLE
	PS C:\> $Folder = 'C:\reports\'
	PS C:\> $FolderSize = (Get-ChildItem -Path $Folder |measure -Property Length -Sum).Sum
	PS C:\> Get-ChildItem -Path $Folder -File |sort Length -Descending |select -First 10 |select Name,Length,@{N='SizeBar';E={New-PercentageBar -Value $_.Length -MaxValue $FolderSize}} |ft -au
	Get file size report and add calculated property 'SizeBar' that contains the percent of each file size from the folder size.
.EXAMPLE
	PS C:\> $VolumeC = gwmi Win32_LogicalDisk |? {$_.DeviceID -eq 'c:'}
	PS C:\> Write-Host -NoNewline "Volume C Usage:" -ForegroundColor Yellow; `
	PS C:\> New-PercentageBar -Value ($VolumeC.Size-$VolumeC.Freespace) -MaxValue $VolumeC.Size -DrawBar; "`r"
	Get system volume usage report.
.NOTES
	Author       ::	Roman Gelman.
	Version 1.0  ::	04-Jul-2016  :: Release.
.LINK
	http://www.ps1code.com/single-post/2016/07/16/How-to-create-colored-and-adjustable-Percentage-Bar-in-PowerShell
#>
	
	[CmdletBinding(DefaultParameterSetName = 'PERCENT')]
	Param (
		[Parameter(Mandatory, Position = 1, ValueFromPipeline, ParameterSetName = 'PERCENT')]
		[ValidateRange(0, 100)]
		[int]$Percent
		 ,
		[Parameter(Mandatory, Position = 1, ValueFromPipeline, ParameterSetName = 'VALUE')]
		[ValidateRange(0, [double]::MaxValue)]
		[double]$Value
		 ,
		[Parameter(Mandatory, Position = 2, ParameterSetName = 'VALUE')]
		[ValidateRange(1, [double]::MaxValue)]
		[double]$MaxValue
		 ,
		[Parameter(Mandatory = $false, Position = 3)]
		[Alias("BarSize", "Length")]
		[ValidateRange(10, 100)]
		[int]$BarLength = 20
		 ,
		[Parameter(Mandatory = $false, Position = 4)]
		[ValidateSet("SimpleThin", "SimpleThick1", "SimpleThick2", "AdvancedThin1", "AdvancedThin2", "AdvancedThick")]
		[string]$BarView = "SimpleThin"
		 ,
		[Parameter(Mandatory = $false, Position = 5)]
		[ValidateRange(50, 80)]
		[int]$GreenBorder = 60
		 ,
		[Parameter(Mandatory = $false, Position = 6)]
		[ValidateRange(80, 90)]
		[int]$YellowBorder = 80
		 ,
		[Parameter(Mandatory = $false)]
		[switch]$NoPercent
		 ,
		[Parameter(Mandatory = $false)]
		[switch]$DrawBar
	)
	
	Begin
	{
		
		If ($PSBoundParameters.ContainsKey('VALUE'))
		{
			
			If ($Value -gt $MaxValue)
			{
				Throw "The [-Value] parameter cannot be greater than [-MaxValue]!"
			}
			Else
			{
				$Percent = $Value/$MaxValue * 100 -as [int]
			}
		}
		
		If ($YellowBorder -le $GreenBorder) { Throw "The [-YellowBorder] value must be greater than [-GreenBorder]!" }
		
		Function Set-BarView ($View)
		{
			Switch -exact ($View)
			{
				"SimpleThin"	{ $GreenChar = [char]9632; $YellowChar = [char]9632; $RedChar = [char]9632; $EmptyChar = "-"; Break }
				"SimpleThick1"	{ $GreenChar = [char]9608; $YellowChar = [char]9608; $RedChar = [char]9608; $EmptyChar = "-"; Break }
				"SimpleThick2"	{ $GreenChar = [char]9612; $YellowChar = [char]9612; $RedChar = [char]9612; $EmptyChar = "-"; Break }
				"AdvancedThin1"	{ $GreenChar = [char]9632; $YellowChar = [char]9632; $RedChar = [char]9632; $EmptyChar = [char]9476; Break }
				"AdvancedThin2"	{ $GreenChar = [char]9642; $YellowChar = [char]9642; $RedChar = [char]9642; $EmptyChar = [char]9643; Break }
				"AdvancedThick"	{ $GreenChar = [char]9617; $YellowChar = [char]9618; $RedChar = [char]9619; $EmptyChar = [char]9482; Break }
			}
			$Properties = [ordered]@{
				Char1 = $GreenChar
				Char2 = $YellowChar
				Char3 = $RedChar
				Char4 = $EmptyChar
			}
			$Object = New-Object PSObject -Property $Properties
			$Object
		} #End Function Set-BarView
		
		$BarChars = Set-BarView -View $BarView
		$Bar = $null
		
		Function Draw-Bar
		{
			
			Param (
				[Parameter(Mandatory)]
				[string]$Char
				 ,
				[Parameter(Mandatory = $false)]
				[string]$Color = 'White'
				 ,
				[Parameter(Mandatory = $false)]
				[boolean]$Draw
			)
			
			If ($Draw)
			{
				Write-Host -NoNewline -ForegroundColor ([System.ConsoleColor]$Color) $Char
			}
			Else
			{
				return $Char
			}
			
		} #End Function Draw-Bar
		
	} #End Begin
	
	Process
	{
		
		If ($NoPercent)
		{
			$Bar += Draw-Bar -Char "[ " -Draw $DrawBar
		}
		Else
		{
			If ($Percent -eq 100) { $Bar += Draw-Bar -Char "$Percent% [ " -Draw $DrawBar }
			ElseIf ($Percent -ge 10) { $Bar += Draw-Bar -Char " $Percent% [ " -Draw $DrawBar }
			Else { $Bar += Draw-Bar -Char "  $Percent% [ " -Draw $DrawBar }
		}
		
		For ($i = 1; $i -le ($BarValue = ([Math]::Round($Percent * $BarLength / 100))); $i++)
		{
			
			If ($i -le ($GreenBorder * $BarLength / 100)) { $Bar += Draw-Bar -Char ($BarChars.Char1) -Color 'DarkGreen' -Draw $DrawBar }
			ElseIf ($i -le ($YellowBorder * $BarLength / 100)) { $Bar += Draw-Bar -Char ($BarChars.Char2) -Color 'Yellow' -Draw $DrawBar }
			Else { $Bar += Draw-Bar -Char ($BarChars.Char3) -Color 'Red' -Draw $DrawBar }
		}
		For ($i = 1; $i -le ($EmptyValue = $BarLength - $BarValue); $i++) { $Bar += Draw-Bar -Char ($BarChars.Char4) -Draw $DrawBar }
		$Bar += Draw-Bar -Char " ]" -Draw $DrawBar
		
	} #End Process
	
	End
	{
		If (!$DrawBar) { return $Bar }
	} #End End
	
} #EndFunction New-PercentageBar

Function New-RandomPassword
{
	
<#
.SYNOPSIS
	Generate a random password.
.DESCRIPTION
	This cmdlet generates a random password with different complexity levels.
.PARAMETER Letters
	Use 'a-z' letters.
.PARAMETER CapitalLetters
	Use 'A-Z' letters.
.PARAMETER Digits
	Use '0-9' digits.
.PARAMETER SpecialCharacters
	Use special characters.
.PARAMETER Complex
	Use all possible characters (letters, capital letters, digits and special characters).
.PARAMETER PasswordLength
	Password length.
.EXAMPLE
	PS C:\> New-RandomPassword -Complex
	Generate complex password with default length.
.EXAMPLE
	PS C:\> New-RandomPassword -Letters -CapitalLetters -Digits -PasswordLength 8
	Generate 8-character password without special characters.
.EXAMPLE
	PS C:\> (1..10) |% {New-RandomPassword -Digits}
	Generate ten 8-digit numbers.
.OUTPUTS
	[System.String] Password.
.NOTES
	Author       ::	Roman Gelman.
	Version 1.0  ::	01-Jun-2016  :: Release.
.LINK
	https://github.com/rgel/PowerShell
#>
	
	[CmdletBinding(DefaultParameterSetName = 'Chars')]
	Param (
		[Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'Chars')]
		[switch]$Letters
		 ,
		[Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'Chars')]
		[switch]$CapitalLetters
		 ,
		[Parameter(Mandatory = $false, Position = 3, ParameterSetName = 'Chars')]
		[switch]$Digits
		 ,
		[Parameter(Mandatory = $false, Position = 4, ParameterSetName = 'Chars')]
		[switch]$SpecialCharacters
		 ,
		[Parameter(Mandatory, Position = 1, ParameterSetName = 'Complex')]
		[switch]$Complex
		 ,
		[Parameter(Mandatory = $false, Position = 5)]
		[ValidateRange(6, 24)]
		[uint16]$PasswordLength = 8
	)
	
	Begin
	{
		
		$loweraz = -join ((97 .. 122) | %{ [char][byte]$_ })
		$UPPERAZ = -join ((65 .. 90) | %{ [char][byte]$_ })
		$digit09 = -join ((48 .. 57) | %{ [char][byte]$_ })
		$special = -join ((33 .. 47) | %{ [char][byte]$_ }) + (-join ((58 .. 64) | %{ [char][byte]$_ })) + (-join ((91 .. 95) | %{ [char][byte]$_ }))
		$CharSet = ''
		$i = 0
		### How many character groups choicen ###
		If ($PSCmdlet.ParameterSetName -eq 'Chars')
		{
			If ($PSBoundParameters.ContainsKey('CapitalLetters')) { $i++ }
			If ($PSBoundParameters.ContainsKey('Letters')) { $i++ }
			If ($PSBoundParameters.ContainsKey('SpecialCharacters')) { $i++ }
			If ($PSBoundParameters.ContainsKey('Digits')) { $i++ }
		}
		ElseIf ($PSCmdlet.ParameterSetName -eq 'Complex') { $i = 4 }
		
		If (!$i) { Throw "You have to choice the password complexity!" }
	}
	
	Process
	{
		
		### How many characters in the each group ###
		$CharCount = [math]::Truncate($PasswordLength/$i)
		
		If ($PSCmdlet.ParameterSetName -eq 'Chars')
		{
			If ($PSBoundParameters.ContainsKey('CapitalLetters')) { $CharSet += -join ($UPPERAZ.ToCharArray() | Get-Random -Count $CharCount) }
			If ($PSBoundParameters.ContainsKey('Letters')) { $CharSet += -join ($loweraz.ToCharArray() | Get-Random -Count $CharCount) }
			If ($PSBoundParameters.ContainsKey('SpecialCharacters')) { $CharSet += -join ($special.ToCharArray() | Get-Random -Count $CharCount) }
			If ($PSBoundParameters.ContainsKey('Digits')) { $CharSet += -join ($digit09.ToCharArray() | Get-Random -Count $CharCount) }
		}
		ElseIf ($PSCmdlet.ParameterSetName -eq 'Complex')
		{
			$CharSet = -join ($UPPERAZ.ToCharArray() | Get-Random -Count $CharCount) + `
			(-join ($loweraz.ToCharArray() | Get-Random -Count $CharCount)) + `
			(-join ($special.ToCharArray() | Get-Random -Count $CharCount)) + `
			(-join ($digit09.ToCharArray() | Get-Random -Count $CharCount))
		}
		
		### Additional characters if not divided evenly between all groups ###
		If ($PasswordLength -gt $CharCount * $i)
		{
			If ($PSCmdlet.ParameterSetName -eq 'Chars')
			{
				If ($PSBoundParameters.ContainsKey('CapitalLetters')) { $CharSet += -join ($UPPERAZ.ToCharArray() | Get-Random -Count ($PasswordLength - $CharCount * $i)) }
				ElseIf ($PSBoundParameters.ContainsKey('Letters')) { $CharSet += -join ($loweraz.ToCharArray() | Get-Random -Count ($PasswordLength - $CharCount * $i)) }
				ElseIf ($PSBoundParameters.ContainsKey('SpecialCharacters')) { $CharSet += -join ($special.ToCharArray() | Get-Random -Count ($PasswordLength - $CharCount * $i)) }
				ElseIf ($PSBoundParameters.ContainsKey('Digits')) { $CharSet += -join ($digit09.ToCharArray() | Get-Random -Count ($PasswordLength - $CharCount * $i)) }
			}
			ElseIf ($PSCmdlet.ParameterSetName -eq 'Complex') { $CharSet += -join ($loweraz.ToCharArray() | Get-Random -Count ($PasswordLength - $CharCount * $i)) }
		}
	}
	
	End
	{
		
		### Shuffle resultant character set ###
		return -join ($CharSet.ToCharArray() | sort { Get-Random })
	}
	
} #EndFunction New-RandomPassword

Function Start-SleepProgress
{
	
<#
.SYNOPSIS
	Put a script to sleep with progress bar.
.DESCRIPTION
	This function puts a script or cmdlet to sleep for specified interval
	of either seconds/minutes/hours or until specified timestamp.
.PARAMETER Second
	Specifies Seconds to sleep.
.PARAMETER Minute
	Specifies Minutes to sleep.
.PARAMETER Hour
	Specifies Hours to sleep.
.PARAMETER Until
	Specifies date/time to sleep until it.
.PARAMETER Force
	If desired timestamp specified by -Until parameter
	earlier than current time, then assume it will be tomorrow.
.PARAMETER ScriptBlock
	Specifies code to execute after the sleep is finished.
	Must be enclosed in the curly braces {}.
.EXAMPLE
	C:\PS> Start-SleepProgress -Second 20
.EXAMPLE
	C:\PS> Start-SleepProgress 10
	The default are seconds.
.EXAMPLE
	C:\PS> Start-SleepProgress -Minutes 1.5
	Sleep ninety seconds.
.EXAMPLE
	C:\PS> Start-SleepProgress -Hour 1.25
	Sleep one hour and fifteen minutes.
.EXAMPLE
	C:\PS> Start-SleepProgress -Until (Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(1) -ScriptBlock {(Get-Service).Where{$_.Status -eq 'Running'} > '.\services.txt'}
	Take snapshot of all running services and export the list to a text file at midnight.
.EXAMPLE
	C:\PS> for ($i=0; $i -lt 10; $i++) {Start-SleepProgress -s 5 -ScriptBlock {(dir "$env:windir\Temp\" |sort LastWriteTime -Descending).Where({$_.Name -like '*.tmp'},'First')}}
	Every five seconds get the newest ".TMP" file from Windows temp directory. Do it ten times.
.EXAMPLE
	C:\PS> Start-SleepProgress -Until 08:45
	Sleep until today 8:45 AM.
.EXAMPLE
	C:\PS> Start-SleepProgress -Until 08:45 -Force
	Sleep until 8:45 AM. Maybe either today or tomorrow, it depends on the current time.
.EXAMPLE
	C:\PS> Start-SleepProgress -Until 1:45PM
	Sleep until 13:45.
.EXAMPLE
	C:\PS> Start-SleepProgress -Until (Get-Date -Hour 2 -Minute 0 -Second 0).AddDays(1)
	Sleep until tomorrow 2:00 AM.
.NOTES
	Author      :: Roman Gelman @rgelman75
	Requirement :: PowerShell 3.0
	Dependency  :: The maximum sleep interval is 24 hours
	Version 1.0 :: 20-Nov-2016 :: [Release]
	Version 1.1 :: 25-Jun-2017 :: [Change] Minor code optimization, alias added
.LINK
	https://ps1code.com/2016/11/20/sleep-powershell-scripts-progress-bar
#>
	
	[CmdletBinding(DefaultParameterSetName = 'SEC')]
	[Alias("slp")]
	Param (
		[Parameter(Mandatory, Position = 0, ParameterSetName = 'SEC')]
		[ValidateRange(1, 86400)]
		[Alias("Seconds", "s")]
		[uint32]$Second
		 ,
		[Parameter(Mandatory, ParameterSetName = 'MIN')]
		[ValidateRange(1, 1440)]
		[Alias("Minutes", "m")]
		[decimal]$Minute
		 ,
		[Parameter(Mandatory, ParameterSetName = 'HOUR')]
		[ValidateRange(1, 24)]
		[Alias("Hours", "h")]
		[decimal]$Hour
		 ,
		[Parameter(Mandatory, ParameterSetName = 'TIME')]
		[datetime]$Until
		 ,
		[Parameter(Mandatory = $false, ParameterSetName = 'TIME')]
		[switch]$Force
		 ,
		[Parameter(Mandatory = $false)]
		[Alias("RunAfter")]
		[scriptblock]$ScriptBlock
	)
	
	Begin
	{
		switch -exact ($PSCmdlet.ParameterSetName)
		{
			'SEC'
			{
				$TimeSpan = New-TimeSpan -Start (Get-Date) -End (Get-Date).AddSeconds($Second)
				Break
			}
			'MIN'
			{
				$Second = $Minute * 60 -as [uint32]
				$TimeSpan = New-TimeSpan -Start (Get-Date) -End (Get-Date).AddSeconds($Second)
				Break
			}
			'HOUR'
			{
				$Second = $Hour * 3600 -as [uint32]
				$TimeSpan = New-TimeSpan -Start (Get-Date) -End (Get-Date).AddSeconds($Second)
				Break
			}
			'TIME'
			{
				$TimeSpan = New-TimeSpan -Start ([datetime]::Now) -End $Until
				$TotalSecond = $TimeSpan.TotalSeconds
				if ($TotalSecond -le 0)
				{
					if ($Force) { Start-SleepProgress -Until $Until.AddDays(1) }
					else { Throw "The timestamp [ $($Until.ToString()) ] is in the past!`nUse [-Force] parameter to shift the timestamp to tomorrow [ $($Until.AddDays(1)) ]." }
				}
				else
				{
					$Second = $TotalSecond -as [uint32]
				}
			}
			
		}
		
		$h = 'hour'
		$m = 'minute'
		$s = 'second'
		
		$h += if ($TimeSpan.Hours -ne 1) { 's' }
		$m += if ($TimeSpan.Minutes -ne 1) { 's' }
		$s += if ($TimeSpan.Seconds -ne 1) { 's' }
		
		Function Add-LeadingZero
		{
			Param ([Parameter(Mandatory, Position = 0)]
				[int]$Digit)
			$str = $Digit.ToString()
			If ($str.Length -eq 1) { $str = '0' + $str }
			return $str
		} #EndFunction Add-LeadingZero
		
	}
	Process
	{
		if ($PSCmdlet.ParameterSetName -eq 'SEC')
		{
			for ($i = 1; $i -le $Second; $i++)
			{
				
				Write-Progress -Activity "Waiting $($TimeSpan.Hours) $h $($TimeSpan.Minutes) $m and $($TimeSpan.Seconds) $s ..." `
							   -CurrentOperation "Left time: $([int]($Second - $i)) seconds" `
							   -Status "Elapsed time: $i seconds" -PercentComplete (100/$Second * $i)
				Start-Sleep -Milliseconds 980
			}
		}
		else
		{
			for ($i = 1; $i -le $Second; $i++)
			{
				
				$Now = Get-Date
				$TimeElapsed = New-TimeSpan -Start $Now -End $Now.AddSeconds($i)
				$TimeLeft = New-TimeSpan -Start $Now -End $Now.AddSeconds([int]($Second - $i))
				Write-Progress -Activity "Waiting $($TimeSpan.Hours) $h $($TimeSpan.Minutes) $m and $($TimeSpan.Seconds) $s ..." `
							   -CurrentOperation "Left time: $(Add-LeadingZero $TimeLeft.Hours):$(Add-LeadingZero $TimeLeft.Minutes):$(Add-LeadingZero $TimeLeft.Seconds)" `
							   -Status "Elapsed time: $(Add-LeadingZero $TimeElapsed.Hours):$(Add-LeadingZero $TimeElapsed.Minutes):$(Add-LeadingZero $TimeElapsed.Seconds)" `
							   -PercentComplete (100/$Second * $i)
				Start-Sleep -Milliseconds 980
			}
		}
		Write-Progress -Activity "Completed" -Completed
	}
	End
	{
		If ($PSBoundParameters.ContainsKey('ScriptBlock')) { &$ScriptBlock }
	}
} #EndFunction Start-SleepProgress

