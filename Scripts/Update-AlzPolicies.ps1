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
    [string]$ReleaseTag,

    [Parameter()]
    [ValidateScript(
        { Test-Path $_ -PathType 'Container' },
        ErrorMessage = "'{0}' does not exist or is not a directory"
    )]
    [string]$DefinitionFolder = $env:PAC_DEFINITIONS_FOLDER
)

# Install the EPAC module
Install-Module -Name EnterprisePolicyAsCode `
    -Scope CurrentUser `
    -Force -AllowClobber

# Download the latest ALZ policies
Sync-ALZPolicies -GithubRelease "tags/$ReleaseTag" `
    -DefinitionsRootFolder $DefinitionFolder
git add $DefinitionFolder

# Check if there are any policy changes
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
$PolicyVersions = Get-Content -Path './policy-versions.json'
| ConvertFrom-Json
$PolicyVersions.alz = $ReleaseTag
$PolicyVersions | ConvertTo-Json
| Set-Content -Path './policy-versions.json' -Force
git add policy-versions.json

# Stage changes and check if policies are updated
git commit -m "Update to Enterprise Scale release $ReleaseTag"
git push
