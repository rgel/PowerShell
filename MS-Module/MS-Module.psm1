Filter Get-OUTree {

<#
.SYNOPSIS
	Convert AD object's 'DistinguishedName' property to path-like format.
.DESCRIPTION
	This filter convert Active Directory object's 'DistinguishedName' property to path-like format.
.EXAMPLE
	C:\PS> Get-ADUser user1 |Get-OUTree
.EXAMPLE
	C:\PS> Get-ADUser -Filter {SamAccountName -like 'user*'} |select Name,@{N='OUTree';E={$_.DistinguishedName |Get-OUTree}}
	Add calculated property 'OUTree' to existing objects.
	This technique will work with all types of objects (users/computers/groups).
.EXAMPLE
	C:\PS> Get-ADGroup -Filter {SamAccountName -like '134*'} |select Name,@{N='OUTree';E={$_.DistinguishedName |Get-OUTree -IncludeDomainName}} |ft -au
.EXAMPLE
	C:\PS> Get-ADGroupMember 13406 |select Name,@{N='OUTree';E={$_.DistinguishedName |Get-OUTree}} |sort OUTree,Name |ft -au
.EXAMPLE
	C:\PS> $dn1 = 'CN=User1,OU=Home1,OU=Northwest,OU=North,DC=World,DC=co,DC=il'
	C:\PS> $dn2 = 'CN=User2,OU=Home2,OU=Northwest,OU=North,DC=World,DC=co,DC=il'
	C:\PS> $dn1,$dn2 |Get-OUTree -IncludeDomainName
	You will get 2 strings: 'World\North\Northwest\Home1' and 'World\North\Northwest\Home2'.

.INPUTS
	[Microsoft.ActiveDirectory.Management.ADUser[]] Active Directory user objects, returned by Get-ADUser cmdlet.
	[Microsoft.ActiveDirectory.Management.ADGroup[]] Active Directory group objects, returned by Get-ADGroup cmdlet.
	[Microsoft.ActiveDirectory.Management.ADPrincipal[]] Active Directory objects, returned by Get-ADGroupMember cmdlet.
	[Microsoft.ActiveDirectory.Management.ADComputer[]] Active Directory computer objects, returned by Get-ADComputer cmdlet.
	[Microsoft.ActiveDirectory.Management.ADDomainController] Active Directory DC object, returned by Get-ADDomainController cmdlet.
	[Microsoft.ActiveDirectory.Management.ADObject[]] Active Directory user/group objects, returned by Get-ADObject cmdlet.
	Any other ObjectsClasses' objects (organizationalUnit/domainDNS) will be ignored.
	[System.String[]] Strings that represents any object's 'DistinguishedName' property.
.OUTPUTS
	[System.String[]]
.NOTES
	Author: Roman Gelman.
.LINK
	https://github.com/rgel/PowerShell
#>

Param ([Switch]$IncludeDomainName)

If ($IncludeDomainName)	{
	$rgxUserDN2OU = '(?i)^cn=.+?,(?<OUTree>(ou=.+?|cn=.+?),dc=.+?),'
	$rgxGNum = 2
} Else {
	$rgxUserDN2OU = '(?i)^cn=.+?,(?<OUTree>ou=.+?|cn=.+?),dc='
	$rgxGNum = 1
}

Try
	{
		If ($_.GetType().Name -eq 'string') {$DN = $_} ElseIf ($_.GetType().Name -eq 'ADDomainController') {$DN = $_.ComputerObjectDN} Else {$DN = $_.DistinguishedName}
		$arrOU = [Regex]::Match($DN, $rgxUserDN2OU).Groups[$rgxGNum].Value -replace ('ou=|cn=|dc=', $null) -split (',')
		[Array]::Reverse($arrOU)
		return $arrOU -join ('\')
	}
Catch 
	{
		return $null
	}
	
} #EndFilter Get-OUTree
