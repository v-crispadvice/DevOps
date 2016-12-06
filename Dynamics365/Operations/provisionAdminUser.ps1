$CurUser = $env:userdomain + "\" + $env:username
$AdObj = New-Object System.Security.Principal.NTAccount($CurUser)
$strSID = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])
$sqlCmd = "UPDATE .dbo.[USERINFO] SET [SID]='{0}' WHERE [ID]='Admin'" -f $strSID.Value

Invoke-sqlcmd -querytimeout ([int]::MaxValue) -ServerInstance "localhost" -Database "DynamicsAX" -Query $sqlCmd


