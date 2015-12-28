Filter Get-OUTree {

<#
.SYNOPSIS
	Convert AD object's 'DistinguishedName' property to path-like format.
.DESCRIPTION
	This filter convert Active Directory object's 'DistinguishedName' property to path-like format.
	Active Directory hierarchy view like this: 'Domainname\TopLevelOU\North\HR' or without domain name 'TopLevelOU\North\HR'.
.EXAMPLE
	C:\PS> Get-ADUser user1 |Get-OUTree
.EXAMPLE
	C:\PS> Get-ADUser -Filter {SamAccountName -like 'user*'} |select Name,@{N='OUTree';E={$_.DistinguishedName |Get-OUTree}}
	Add calculated property 'OUTree' to existing objects.
	This technique will work with all types of objects (users/computers/groups/OU).
.EXAMPLE
	C:\PS> Get-ADGroup -Filter {SamAccountName -like 'hr*'} |select Name,@{N='OUTree';E={$_.DistinguishedName |Get-OUTree -IncludeDomainName}} |ft -au
.EXAMPLE
	C:\PS> Get-ADGroupMember HR |select Name,@{N='OUTree';E={$_.DistinguishedName |Get-OUTree}} |sort OUTree,Name |ft -au
.EXAMPLE
	C:\PS> Get-ADOrganizationalUnit -Filter {Name -like 'North'} |select @{N='DN';E={$_}},@{N='OUTree';E={$_ |Get-OUTree -IncludeDomainName}} |sort DN
.EXAMPLE
	C:\PS> $dn1 = 'CN=User1,OU=HR,OU=Northwest,OU=North,DC=World,DC=co,DC=il'
	C:\PS> $dn2 = 'CN=User2,CN=Users,DC=World,DC=co,DC=il'
	C:\PS> $dn3 = 'CN=Server1,CN=Computers,DC=World,DC=co,DC=il'
	C:\PS> $dn4 = 'OU=Northwest,OU=North,DC=World,DC=co,DC=il'
	C:\PS> $dn1,$dn2,$dn3,$dn4 |Get-OUTree -IncludeDomainName
	These four DNs for the different AD object types (User/User in the default 'Users' container/Computer/Organizational Unit).
.INPUTS
	[Microsoft.ActiveDirectory.Management.ADUser[]]               Active Directory user objects, returned by Get-ADUser cmdlet.
	[Microsoft.ActiveDirectory.Management.ADGroup[]]              Active Directory group objects, returned by Get-ADGroup cmdlet.
	[Microsoft.ActiveDirectory.Management.ADPrincipal[]]          Active Directory objects, returned by Get-ADGroupMember cmdlet.
	[Microsoft.ActiveDirectory.Management.ADComputer[]]           Active Directory computer objects, returned by Get-ADComputer cmdlet.
	[Microsoft.ActiveDirectory.Management.ADDomainController]     Active Directory DC object, returned by Get-ADDomainController cmdlet.
	[Microsoft.ActiveDirectory.Management.ADObject[]]             Active Directory objects, returned by Get-ADObject cmdlet.
	[Microsoft.ActiveDirectory.Management.ADOrganizationalUnit[]] Active Directory OU object, returned by Get-ADOrganizationalUnit cmdlet.
	Because the object itself is not included in the report, for top level OU containers empty string is returned.
	[System.String[]] Strings that represent any object's 'DistinguishedName' property.
.OUTPUTS
	[System.String[]]
.NOTES
	Author: Roman Gelman.
	Version 1.0 :: 27-Dec-2015 :: Release     ::
	Version 1.1 :: 28-Dec-2015 :: Improvement :: Regex edited to support 'ADOrganizationalUnit' objects itself.
.LINK
	https://goo.gl/wOzNOe
#>

Param ([Switch]$IncludeDomainName)

If ($IncludeDomainName)	{
	$rgxUserDN2OU = '(?i)^(cn|ou)=.+?,(?<OUTree>(ou=.+?|cn=.+?),dc=.+?),'
	$rgxGNum      = 3
} Else {
	$rgxUserDN2OU = '(?i)^(cn|ou)=.+?,(?<OUTree>ou=.+?|cn=.+?),dc='
	$rgxGNum      = 2
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

Export-ModuleMember -Alias '*' -Function '*'
