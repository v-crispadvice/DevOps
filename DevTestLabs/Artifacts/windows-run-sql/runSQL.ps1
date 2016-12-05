Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]
    $scriptFileURI
)

Invoke-sqlcmd -querytimeout ([int]::MaxValue) -ServerInstance "localhost" -Database "master" -InputFile $scriptFileURI