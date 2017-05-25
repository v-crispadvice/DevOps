#parameters
param(
    [Parameter (Mandatory=$True)]
    [string] $accessToken,

    [Parameter (Mandatory=$True)]
    [string] $buildDefinitionName,

    [Parameter (Mandatory=$True)]
    [string] $vstsAccount,

    [Parameter (Mandatory=$True)]
    [string] $vstsProject,

    [Parameter (Mandatory=$True)]
    [string] $vstsBuildArtifact1,

    [Parameter (Mandatory=$True)]
    [string] $vstsBuildArtifact2
)

Set-PSDebug -Strict

#init variables

$vstsApiVersion = "2.0"

$destination = $env:HOMEDRIVE + "\VSTS";

if (($vstsBuildArtifact1) -and ($vstsBuildArtifact2))
{
    # database with demo data
    $databaseName = Split-Path -Path $vstsBuildArtifact1 -Leaf

    $outfileDatabase = $PSScriptRoot + "\" + $databaseName;

    if ($vstsBuildArtifact1.Contains("/")) {
        $vstsBuildArtifact1 = $vstsBuildArtifact1.Replace("/", "%2F")
    }

    # modelstore
    $modelstoreName  = Split-Path -Path $vstsBuildArtifact2 -Leaf
    $outfileModelstore = $PSScriptRoot + "\" + $modelstoreName;
    
    if ($vstsBuildArtifact2.Contains("/")) {
        $vstsBuildArtifact2 = $vstsBuildArtifact2.Replace("/", "%2F")
    }
}
else
{
    $outfile = $PSScriptRoot + "\" + $buildDefinitionName + ".zip";
}


function SetAuthHeaders
{
    return @{Authorization=('Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($accessToken)")))}
}

function GetBuildDefinitionId
{
    $buildDefinitionUri = ("{0}/{1}/_apis/build/definitions?api-version={2}&name={3}" -f $vstsAccount, $vstsProject, $vstsApiVersion, $buildDefinitionName)

    try
    {
        Write-Host "GetBuildDefinitionId from $buildDefinitionUri"
        $buildDef = Invoke-RestMethod -Uri $buildDefinitionUri -Headers $headers -method Get -ErrorAction Stop
        return $buildDef.value.id
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

function GetLatestBuild
{
    param (
        [Parameter(Mandatory=$True)]
        [int] $buildDefinitionId 
    )
    $buildUri = ("{0}/{1}/_apis/build/builds?api-version={2}&definitions={3}&resultFilter=succeeded" -f $vstsAccount, $vstsProject, $vstsApiVersion, $buildDefinitionId);

    try 
    {
        Write-Host "GetLatestBuild from $buildUri"
        $builds = Invoke-RestMethod -Uri $buildUri -Headers $headers -Method Get -ErrorAction Stop | ConvertTo-Json | ConvertFrom-Json
        return $builds.value[0].id
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

function DownloadBuildArtifactFromContainer
{
    param (
        [Parameter(Mandatory=$True)]
        [PSObject] $containerId,

        [Parameter(Mandatory=$True)]
        [string] $artifactPath,

        [Parameter(Mandatory=$True)]
        [string] $artifactOutput
    )

    $containerUri = ("{0}/_apis/resources/Containers/{1}?itemPath={2}" -f $vstsAccount, $containerId, $artifactPath);
            
    Write-Host "Download from $containerUri"
    Invoke-RestMethod -Uri $containerUri -Headers $headers -Method Get -Outfile $artifactOutput -ErrorAction Stop

    #assume that all artifacts are zipped
    [System.IO.Compression.ZipFile]::ExtractToDirectory($artifactOutput, $destination)

    Remove-Item $artifactOutput
}

function DownloadBuildArtifacts
{
    $headers = SetAuthHeaders
    $buildId = GetLatestBuild ( GetBuildDefinitionId )
    $artifactsUri = ("{0}/{1}/_apis/build/builds/{2}/Artifacts?api-version={3}" -f $vstsAccount, $vstsProject, $buildId, $vstsApiVersion);

    try 
    {
        if (Test-Path $destination -PathType Container)
        {
            Remove-Item -Path $destination -Force -Recurse -Verbose
        }

        Write-Host "Get artifacts from $artifactsUri"
        $artifacts = Invoke-RestMethod -Uri $artifactsUri -Headers $headers -Method Get  -ErrorAction Stop | ConvertTo-Json -Depth 3 | ConvertFrom-Json
        $downloadUri = $artifacts.value.resource.downloadUrl
        $containerId = $artifacts.value.resource.data -replace "#/","" -replace "/drops", ""

        [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null 

        if ($downloadUri -is [system.array])
        {
            foreach ($artifactUri in $downloadUri) #download logs and drops (not yet tested)
            {
                Write-Host "Download from $artifactUri"
                Invoke-RestMethod -Uri $artifactUri -Headers $headers -Method Get -Outfile $outfile -ErrorAction Stop

                [System.IO.Compression.ZipFile]::ExtractToDirectory($outfile, $destination)
            }
        }
        else 
        {
            if (($containerId) -and ($databasePath) -and ($modelstorePath))
            {
                DownloadBuildArtifactFromContainer  $containerId $vstsBuildArtifact1 $outfileDatabase
                DownloadBuildArtifactFromContainer  $containerId $vstsBuildArtifact2 $outfileModelstore

            }
            else #download in one zip
            {
                Write-Host "Download from $downloadUri"
                Invoke-RestMethod -Uri $downloadUri -Headers $headers -Method Get -Outfile $outfile -ErrorAction Stop

                [System.IO.Compression.ZipFile]::ExtractToDirectory($outfile, $destination)
            }

        }
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

DownloadBuildArtifacts 