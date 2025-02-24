param (
    [Parameter(Required)]
    [ValidateScript(
        { $_ -match '^\d{4}\-\d{2}\-\d{2}$' },
        ErrorMessage = "'{0}' is not in the format YYYY-MM-DD."
    )]
    [ValidateScript(
        { [Date]$_ },
        ErrorMessage = "'{0}' is not a valid date"
    )]
    [string]$ReleaseDate,

    [Parameter()]
    [ValidateScript(
        { Test-Path $_ -PathType 'Container' },
        ErrorMessage = "'{0}' does not exist or is not a directory"
    )]
    [string]$DefinitionFolder = $env:PAC_DEFINITIONS_FOLDER
)

# Download the latest AMBA policies
$ZipFile = Join-Path ([System.IO.Path]::GetTempPath()) 'amba-export.zip'
$ExtractDir = Join-Path ([System.IO.Path]::GetTempPath()) 'amba-export-main'

$Headers = @{}
if ($env:GITHUB_TOKEN)
{
    $Headers['Authorization'] = "Bearer $env:GITHUB_TOKEN"
}

Invoke-WebRequest -Uri 'https://github.com/anwather/amba-export/archive/refs/heads/main.zip' `
    -Headers $Headers `
    -OutFile $ZipFile
Expand-Archive -Path $ZipFile `
    -DestinationPath ([System.IO.Path]::GetTempPath()) `
    -Force

# Clear the existing AMBA folders
$paDir = Join-Path $DefinitionFolder 'policyAssignments/AMBA'
$pdDir = Join-Path $DefinitionFolder 'policyDefinitions/AMBA'
$psdDir = Join-Path $DefinitionFolder 'policySetDefinitions/AMBA'

Remove-Item -Path $paDir -Recurse -Force
Remove-Item -Path $pdDir -Recurse -Force
Remove-Item -Path $psdDir -Recurse -Force

New-Item -Path $paDir -ItemType Directory
New-Item -Path $pdDir -ItemType Directory
New-Item -Path $psdDir -ItemType Directory

# Move the AMBA policies to the correct folder
Move-Item -Path (Join-Path $ExtractDir 'Definitions/policyAssignments/*') `
    -Destination $paDir `
    -Force
Move-Item -Path (Join-Path $ExtractDir 'Definitions/policyDefinitions/*') `
    -Destination $pdDir `
    -Force
Move-Item -Path (Join-Path $ExtractDir 'Definitions/policySetDefinitions/*') `
    -Destination $psdDir `
    -Force

# Check if there are any policy changes
git add $DefinitionFolder
if (git diff --staged --quiet)
{
    Write-Host 'No changes detected'
    'PolicyUpdates=false' |
        Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
} else
{
    Write-Host 'Changes detected'
    'PolicyUpdates=true' |
        Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
}

# Update the policyDates file
if (Test-Path -Path './policy-versions.json' -PathType 'Leaf')
{
    $PolicyVersions = Get-Content -Path './policy-versions.json' |
        ConvertFrom-Json
} else
{
    $PolicyVersions = @{}
}
$PolicyVersions['amba'] = $env:Latest
$PolicyVersions |
    ConvertTo-Json |
    Set-Content -Path './policy-versions.json' -Force
git add policy-versions.json

# Stage changes and check if policies are updated
git commit -m "Update to AMBA Export $ReleaseTag"
git push
