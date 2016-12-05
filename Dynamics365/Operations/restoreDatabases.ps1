Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]
    $modelstoreURI,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]
    $modelstoreDB
)

function ImportAXModule($axModuleName, $disableNameChecking, $isFile)
{
    # copied from C:\Program Files\Microsoft Dynamics AX\60\ManagementUtilities\Microsoft.Dynamics.ManagementUtilities.ps1
    try
    {
        $outputmessage = "Importing " + $axModuleName
        Write-Output $outputmessage

        if($isFile -eq $true)
        {
            $dynamicsSetupRegKey = Get-Item "HKLM:\SOFTWARE\Microsoft\Dynamics\6.0\Setup"
            $sourceDir = $dynamicsSetupRegKey.GetValue("InstallDir")
            $axModuleName = "ManagementUtilities\" + $axModuleName + ".dll"
            $axModuleName = join-path $sourceDir $axModuleName
        }
        if($disableNameChecking -eq $true)
        {
            import-module $axModuleName -DisableNameChecking
        }
        else
        {
            import-module $axModuleName
        }
    }
    catch
    {
        $outputmessage = "Could not load file " + $axModuleName
        Write-Output $outputmessage
    }
}

function InitManagementTools
{
    # copied from C:\Program Files\Microsoft Dynamics AX\60\ManagementUtilities\Microsoft.Dynamics.ManagementUtilities.ps1
    $dynamicsSetupRegKey = Get-Item "HKLM:\SOFTWARE\Microsoft\Dynamics\6.0\Setup"
    $sourceDir = $dynamicsSetupRegKey.GetValue("InstallDir")
    $dynamicsAXModulesPath = join-path $sourceDir "ManagementUtilities\Modules"

    if (-not (test-path "$dynamicsAXModulesPath")) 
    {
        throw "$dynamicsAXModulesPath needed"
    } 

    $env:PSModulePath = $env:PSModulePath + ";" + $dynamicsAXModulesPath

    ImportAXModule "AxUtilLib" $false $true

    ImportAXModule "AxUtilLib.PowerShell" $true $false

    ImportAXModule "Microsoft.Dynamics.Administration" $false $false
    ImportAXModule "Microsoft.Dynamics.AX.Framework.Management" $false $false
}

if (-not (test-path $modelstoreURI)) 
{
    throw "$modelstoreURI not found"
}

$modelstorePath = Split-Path -Path $modelstoreURI
Start-Transcript -path "$modelstorePath\importModelstore.log" -append

$modelstoreFile = (Split-Path -Path $modelstoreURI -Leaf -Resolve).ToLower()
if ($modelstoreFile -match "^.*\.(zip|rar|7z|001)$" )
{
    if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) 
    {
        throw "$env:ProgramFiles\7-Zip\7z.exe needed"
    } 
    
    set-alias sz "$env:ProgramFiles\7-Zip\7z.exe" 
    Set-Location $modelstorePath

    sz e $modelstoreURI

    $modelstoreFile = (sz l $modelstoreURI | where {$_ -match ".*\.axmodelstore$"}) -split "\s" | Select-Object -Last 1
    $modelstoreURI = $modelstorePath + "\" + $modelstoreFile
}

InitManagementTools

Initialize-AXModelStore -Server "localhost" -Database $modelstoreDB

Import-AXModelStore -File $modelstoreURI -Details -Verbose -NoPrompt -IdConflict 1 -Server "localhost" -Database $modelstoreDB