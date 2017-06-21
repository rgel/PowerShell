# ![powershelllogo](https://cloud.githubusercontent.com/assets/6964549/17082276/0ded5776-5180-11e6-8276-d772295362b9.png)
## PowerShell Scripts & Modules

### SCRIPTS

|No|Script|Description|
|----|----|----|
|1|[<b>Get-NetStat.ps1</b>](https://github.com/rgel/PowerShell/blob/master/SysAdminTools/Get-NetStat.ps1)|`netstat.exe` regex [parser](http://www.lazywinadmin.com/2014/08/powershell-parse-this-netstatexe.html)|
|2|[<b>Get-MOTD.ps1</b>](https://github.com/rgel/PowerShell/blob/master/Get-MOTD.ps1)|[Edited](https://ps1code.com/2016/07/16/percentage-bar-powershell) version of `Get-MOTD` function written by Michal Millar|

### [<ins>MS-Module</ins>](https://github.com/rgel/PowerShell/tree/master/MS-Module)

To install this module, drop the entire '<b>MS-Module</b>' folder into one of your module directories.

The default PowerShell module paths are listed in the `$env:PSModulePath` environment variable.

To make it look better, split the paths in this manner: `$env:PSModulePath -split ';'`

The default per-user module path is: `"$env:HOMEDRIVE$env:HOMEPATH\Documents\WindowsPowerShell\Modules"`.

The default computer-level module path is: `"$env:windir\System32\WindowsPowerShell\v1.0\Modules"`.

To use the module, type following command: `Import-Module MS-Module -Force -Verbose`.

To get the module version type following command: `Get-Module -ListAvailable |? {$_.Name -eq 'MS-Module'}`.

To see the commands imported, type `Get-Command -Module MS-Module`.

For help on each individual cmdlet or function, run `Get-Help CmdletName -Full [-Online][-Examples]`.

### MODULES 

#### <b><ins>MS-Module Cmdlets:</ins></b>

|No|Cmdlet|Description|
|----|----|----|
|1|[<b>Get-OUPath</b>](https://ps1code.com/category/powershell/ms-module/)|Convert AD object's <i>DistinguishedName</i> property to a path like format. Distinguished name `CN=User1,OU=Sales,OU=North,DC=contoso,DC=com` = `Contoso\North\Sales\User1` in the path format|
|2|[<b>Write-Menu</b>](https://ps1code.com/2016/04/21/write-menu-powershell)|Create colored, interactive and dynamic Menu in the PowerShell console|
|3|[<b>New-PercentageBar</b>](https://ps1code.com/2016/07/16/percentage-bar-powershell)|Create colored and adjustable Percentage Bar in the PowerShell|
|4|[<b>New-RandomPassword</b>](https://cloud.githubusercontent.com/assets/6964549/17292816/ec6ad06c-57f4-11e6-9c36-7ead98ba6e99.png)|Generate a random password with custom length and complexity|
|5|[<b>Start-SleepProgress</b>](https://ps1code.com/category/powershell/ms-module/)|Put a script or cmdlet to sleep for specified `interval` or until specified `timestamp`|
