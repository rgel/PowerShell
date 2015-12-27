# PowerShell Repo
## Scripts & Modules

### </b><ins>Get-NetStat.ps1</ins></b>

###### <b>["Netstat.exe" regex parser</b>] (http://www.lazywinadmin.com/2014/08/powershell-parse-this-netstatexe.html)

### </b><ins>[MS-Module.psm1</ins></b>] (https://github.com/rgel/PowerShell/blob/master/MS-Module/MS-Module.psm1)

To install this module, drop the entire '<b>MS-Module</b>' folder into one of your module directories.

The default PowerShell module paths are listed in the `$env:PSModulePath` environment variable.

To make it look better, split the paths in this manner `$env:PSModulePath -split ';'`

The default per-user module path is: `"$env:HOMEDRIVE$env:HOMEPATH\Documents\WindowsPowerShell\Modules"`.

The default computer-level module path is: `"$env:windir\System32\WindowsPowerShell\v1.0\Modules"`.

To use the module, type following command: `Import-Module MS-Module -Force -Verbose`.

To see the commands imported, type `Get-Command -Module MS-Module`.

For help on each individual cmdlet or function, run `Get-Help CmdletName -Full [-Online][-Examples]`.

##### <ins>Cmdlets:</ins>

###### <b>1. Get-OUTree</b>

This filter convert AD object's 'DistinguishedName' property to path-like format.

![Get-OUTree] (https://cloud.githubusercontent.com/assets/6964549/12010335/a72f9cb2-acaa-11e5-8eba-73809251137c.png)

You can pipe to the filter objects, returned by following ActiveDirectory Module's cmdlets:

`Get-ADUser`, `Get-ADGroup`, `Get-ADGroupMember`, `Get-ADComputer`, `Get-ADDomainController`, `Get-ADOject` or string, that contains 'DistinguishedName'.

See content based help for more examples: `Get-Help Get-OUTree -Examples`.
