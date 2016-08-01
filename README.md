# ![powershelllogo](https://cloud.githubusercontent.com/assets/6964549/17082276/0ded5776-5180-11e6-8276-d772295362b9.png) PowerShell Repo
## Scripts & Modules

### <ins>[Get-NetStat.ps1</ins>] (https://github.com/rgel/PowerShell/blob/master/SysAdminTools/Get-NetStat.ps1)

###### <b>["Netstat.exe" regex parser</b>] (http://www.lazywinadmin.com/2014/08/powershell-parse-this-netstatexe.html)

### <ins>[Get-MOTD.ps1</ins>] (https://github.com/rgel/PowerShell/blob/master/Get-MOTD.ps1)

###### <b>[Edited version of Get-MOTD function written by Michal Millar</b>] (http://www.ps1code.com/single-post/2016/07/16/How-to-create-colored-and-adjustable-Percentage-Bar-in-PowerShell)

### <ins>[MS-Module.psm1</ins>] (https://github.com/rgel/PowerShell/blob/master/MS-Module/MS-Module.psm1)

To install this module, drop the entire '<b>MS-Module</b>' folder into one of your module directories.

The default PowerShell module paths are listed in the `$env:PSModulePath` environment variable.

To make it look better, split the paths in this manner `$env:PSModulePath -split ';'`

The default per-user module path is: `"$env:HOMEDRIVE$env:HOMEPATH\Documents\WindowsPowerShell\Modules"`.

The default computer-level module path is: `"$env:windir\System32\WindowsPowerShell\v1.0\Modules"`.

To use the module, type following command: `Import-Module MS-Module -Force -Verbose`.

To see the commands imported, type `Get-Command -Module MS-Module`.

For help on each individual cmdlet or function, run `Get-Help CmdletName -Full [-Online][-Examples]`.

#### <b><ins>MS-Module Cmdlets:</ins></b>

|No|Cmdlet|Description|
|----|----|----|
|1|<b> [Get-OUPath</b>] (http://www.ps1code.com/single-post/2016/05/20/How-to-convert-AD-objects%E2%80%99-DistinguishedName-property-to-path-like-format)|This filter convert AD object's 'DistinguishedName' property to path like format. Distinguished name `CN=User1,OU=Sales,OU=North,DC=contoso,DC=com` = `Contoso\North\Sales\User1` in path format|
|2|<b> [Write-Menu</b>] (http://www.ps1code.com/single-post/2016/04/21/How-to-create-interactive-dynamic-Menu-in-PowerShell)|This function creates colored, interactive and dynamic Menu in the PowerShell console|
|3|<b> [New-PercentageBar</b>] (http://www.ps1code.com/single-post/2016/07/16/How-to-create-colored-and-adjustable-Percentage-Bar-in-PowerShell)|This function creates colored and adjustable Percentage Bar in the PowerShell|
|4|<b> [New-RandomPassword</b>] (http://powershell.com/cs/blogs/tips/archive/2016/05/23/one-liner-random-password-generator.aspx)|This function generates a random password with custom length and complexity. Thanks to the Powershell.com for the idea|
