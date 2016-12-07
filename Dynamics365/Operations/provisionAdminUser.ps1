If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

$strUser = "{0}\{1}" -f $env:userdomain, $env:username
$objUser = New-Object System.Security.Principal.NTAccount($strUser)
$strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
$strSQL = "UPDATE .dbo.[USERINFO] SET [SID]='{0}' WHERE [ID]='Admin'" -f $strSID

Invoke-sqlcmd -querytimeout ([int]::MaxValue) -ServerInstance "localhost" -Database "MicrosoftDynamicsAX" -Query $strSQL