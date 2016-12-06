#parameters
param(
    [Parameter (Mandatory=$True)]
    [string] $setupPath
)

Set-PSDebug -Strict

function CompleteWithConfigFile
{
    try
    {
    	$newProcess = new-object System.Diagnostics.ProcessStartInfo "setup.exe" 
        $newProcess.WorkingDirectory = "$setupPath" 

	    $newProcess.Verb = "runas"; 

	    $newProcess.Arguments = "/IAcceptSQLServerLicenseTerms /ConfigurationFile=$PSScriptRoot\ConfigurationFile.ini" 
	
	
        Write-Host $newProcess.Arguments 


    	$process = [System.Diagnostics.Process]::Start($newProcess); 

    }
    catch
    {
        if (($null -ne $Error[0]) -and ($null -ne $Error[0].Exception) -and ($null -ne $Error[0].Exception.Message))
        {
            $errMsg = $Error[0].Exception.Message
            Write-Host $errMsg
        }
        exit -1
    }
}

CompleteWithConfigFile