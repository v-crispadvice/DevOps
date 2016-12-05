Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ScriptFile
)

Invoke-sqlcmd -querytimeout ([int]::MaxValue) -ServerInstance "localhost" -Database "master" -InputFile $ScriptFile