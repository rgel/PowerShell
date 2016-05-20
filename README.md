# PowerShell Repo
## Scripts & Modules

### </b><ins>[Get-NetStat.ps1</ins></b>] (https://github.com/rgel/PowerShell/blob/master/SysAdminTools/Get-NetStat.ps1)

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

###### <b>1. Get-OUPath</b> (http://goo.gl/NwlePh)

This filter convert AD object's 'DistinguishedName' property to path like format.

Distinguished name `CN=User1,OU=Sales,OU=North,DC=contoso,DC=com` = `Contoso\North\Sales\User1` in path format.

###### <b>2. [Write-Menu</b>] (http://goo.gl/MgLch1)

This function creates colored, interactive and dynamic Menu in the PowerShell console.
