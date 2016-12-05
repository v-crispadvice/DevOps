Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SQLFile
)

Invoke-sqlcmd -querytimeout ([int]::MaxValue) -ServerInstance "localhost" -Database "master" -InputFile $SQLFile