# ![powershelllogo](https://cloud.githubusercontent.com/assets/6964549/17082276/0ded5776-5180-11e6-8276-d772295362b9.png)
## PowerShell Scripts & Modules

### [<ins>Get-NetStat.ps1</ins>](https://github.com/rgel/PowerShell/blob/master/SysAdminTools/Get-NetStat.ps1)

###### [<b>"Netstat.exe" regex parser</b>](http://www.lazywinadmin.com/2014/08/powershell-parse-this-netstatexe.html)

### [<ins>Get-MOTD.ps1</ins>](https://github.com/rgel/PowerShell/blob/master/Get-MOTD.ps1)

###### [<b>Edited version of Get-MOTD function written by Michal Millar</b>](http://www.ps1code.com/single-post/2016/07/16/How-to-create-colored-and-adjustable-Percentage-Bar-in-PowerShell)

### [<ins>MS-Module.psm1</ins>](https://github.com/rgel/PowerShell/blob/master/MS-Module/MS-Module.psm1)

To install this module, drop the entire '<b>MS-Module</b>' folder into one of your module directories.

The default PowerShell module paths are listed in the `$env:PSModulePath` environment variable.

To make it look better, split the paths in this manner: `$env:PSModulePath -split ';'`

The default per-user module path is: `"$env:HOMEDRIVE$env:HOMEPATH\Documents\WindowsPowerShell\Modules"`.

The default computer-level module path is: `"$env:windir\System32\WindowsPowerShell\v1.0\Modules"`.

To use the module, type following command: `Import-Module MS-Module -Force -Verbose`.

To get the module version type following command: `Get-Module -ListAvailable |? {$_.Name -eq 'MS-Module'}`.

To see the commands imported, type `Get-Command -Module MS-Module`.

For help on each individual cmdlet or function, run `Get-Help CmdletName -Full [-Online][-Examples]`.

#### <b><ins>MS-Module Cmdlets:</ins></b>

|No|Cmdlet|Description|
|----|----|----|
|1|[<b>Get-OUPath</b>](https://ps1code.com/category/powershell/ms-module/)|This filter converts AD object's <i>DistinguishedName</i> property to a path like format. Distinguished name `CN=User1,OU=Sales,OU=North,DC=contoso,DC=com` = `Contoso\North\Sales\User1` in the path format|
|2|[<b>Write-Menu</b>](https://ps1code.com/category/powershell/ms-module/)|This function creates colored, interactive and dynamic Menu in the PowerShell console|
|3|[<b>New-PercentageBar</b>](https://ps1code.com/2016/07/16/percentage-bar-powershell)|This function creates colored and adjustable Percentage Bar in the PowerShell|
|4|[<b>New-RandomPassword</b>](https://cloud.githubusercontent.com/assets/6964549/17292816/ec6ad06c-57f4-11e6-9c36-7ead98ba6e99.png)|This function generates a random password with custom length and complexity. Thanks to the Powershell.com for the [idea](http://powershell.com/cs/blogs/tips/archive/2016/05/23/one-liner-random-password-generator.aspx)|
|5|[<b>Start-SleepProgress</b>](https://ps1code.com/category/powershell/ms-module/)|This function puts a script or cmdlet in the sleep for specified interval of either seconds/minutes/hours or until specified timestamp|

