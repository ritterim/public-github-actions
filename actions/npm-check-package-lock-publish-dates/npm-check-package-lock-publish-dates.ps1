#Requires -Version 7

# Scan the package-lock.json and lookup last publish dates for all resolved versions.
# This should be placed before your "npm ci" step.
# Caching the $CacheDirectory into your GitHub build cache will speed up future runs.

# Background:
#
# The command: npm view "@babel/plugin-syntax-jsx@7.22.5" time --json
# Produces JSON that looks like
# {
#  "created": "2017-10-30T18:34:20.769Z",
#  "modified": "2025-09-05T15:05:57.457Z",
#  "7.0.0-beta.4": "2017-10-30T18:34:20.769Z",
#  "7.0.0-beta.5": "2017-10-30T20:56:03.707Z"
# }

[CmdletBinding()]
Param(
    [string]
    $ProjectDirectory = ".",

    [string]
    $CacheDirectory = "~/.cache/npm-publish-dates",

    [int]
    $MinimumPublishAgeDays = 7
)

Write-Host "ProjectDirectory: $($ProjectDirectory)"
Write-Host "CacheDirectory: $($CacheDirectory)"
Write-Host "MinimumPublishAgeDays: $($MinimumPublishAgeDays)"
$global:CacheHit = 0
$global:CacheMiss = 0

function Get-NPMCommandPath {
    #TODO: We might have to look for "npm.exe" on Windows machines?

    $npm = Get-Command -Name "npm" -ErrorAction Continue
    if (!($npm)) {
        throw [System.Management.Automation.CommandNotFoundException]::new("The command 'npm' was not found.")
    }
    if ($npm.CommandType -ne "Application") {
        throw "The CommandType for 'npm' is not 'Applicaiton'."
    }
    if ([string]::IsNullOrEmpty($npm.Path)) {
        throw "No 'Path' for the 'npm' command."
    }

    $version = $(&npm -version)
    if ([string]::IsNullOrEmpty($version)) {
        throw "Failed to get anything back from 'npm -version' command."
    }
    #Write-Debug "npm version: $($version)"

    return $npm.Path
}

function Get-PackageLock {
    Param(
        [Parameter(Mandatory)]
        [string]
        $ProjectDirectory
    )

    if (-not (Test-Path $ProjectDirectory -PathType Container)) {
        throw [System.IO.DirectoryNotFoundException]::new("The project directory '$($ProjectDirectory)' was not found.")
    }

    $packageLockFileName = "package-lock.json"
    $packageLockFilePath = Join-Path -Path $ProjectDirectory -ChildPath $packageLockFileName
    Write-Debug "package-lock path: $($packageLockFilePath)"
    if (-not (Test-Path $packageLockFilePath -PathType Leaf)) {
        throw [System.IO.FileNotFoundException]::new("The '$($packageLockFileName)' was not found in the project directory.")
    }
    
    $jsonString = Get-Content -Path $packageLockFilePath -Raw

    # package-lock.json files often have at least one key that is the empty string
    #   "packages": {
    #     "": {
    $jsonString = $jsonString -replace '"":', '"(root)":'

    $jsonObject = $jsonString | ConvertFrom-Json
    return [PSCustomObject]@{
        Name = $packageLockFileName
        Path = $packageLockFilePath
        Value = $jsonObject
    }
}

function Test-StringIsNodeModulesFolderName {
    Param(
        [Parameter(Mandatory)]
        [string]
        $PackageKeyNamePart
    )

    $regexPattern = '^node_modules$'
    $result = $PackageKeyNamePart -match $regexPattern
    return $result
}

function Test-StringIsNpmPackageScope {
    Param(
        [Parameter(Mandatory)]
        [string]
        $PackageKeyNamePart
    )

    $regexPattern = '^@[a-z0-9-]+$'
    $result = $PackageKeyNamePart -match $regexPattern
    return $result
}

function Test-StringIsNpmPackageName {
    Param(
        [Parameter(Mandatory)]
        [string]
        $PackageKeyNamePart
    )

    $regexPattern = '^[a-z0-9]{1}[a-z0-9-._]{0,213}$'
    $result = $PackageKeyNamePart -match $regexPattern
    return $result
}

function Test-NpmPackageVersionString {
    Param(
        [Parameter(Mandatory)]
        [string]
        $Version
    )

    $regexPattern = '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'
    $result = $Version -match $regexPattern
    return $result
}

function Get-LastOccurrenceOfNodeModulesFolderInArray {
    Param(
        [Parameter(Mandatory)]
        [string[]]
        $PackageKeyNameParts
    )
    for ($i = $PackageKeyNameParts.Count - 1; $i -ge 0; $i--) {
        if (Test-StringIsNodeModulesFolderName -PackageKeyNamePart $PackageKeyNameParts[$i]) {
            return $i
        }
    }
    return $null
}

function Split-PackageKeyName {
    Param(
        [Parameter(Mandatory)]
        [string]
        $PackageKeyName
    )

    $result = [PSCustomObject]@{
        Valid = $false
        Scope = $null
        Package = $null
        PackageSpec = $null
    }
    $parts = $PackageKeyName -split "/"
    $lastNodeModulesFolderIndex = Get-LastOccurrenceOfNodeModulesFolderInArray -PackageKeyNameParts $parts
    if ($lastNodeModulesFolderIndex -ge 0) {
        $parts = $parts[($lastNodeModulesFolderIndex + 1)..($parts.Length - 1)]
    }
    #Write-Debug "  parts: $($parts)"

    if ($parts.Count -eq 1) {
        if (Test-StringIsNpmPackageName -PackageKeyNamePart $parts[0]) {
            $result.Valid = $true
            $result.Scope = $null
            $result.Package = $parts[0]
            $result.PackageSpec = $parts[0]
        } else {
            throw "part '$($parts[0])' is not a valid package name."
        }
    }
    if ($parts.Count -eq 2) {
        if ((Test-StringIsNpmPackageScope -PackageKeyNamePart $parts[0]) -and (Test-StringIsNpmPackageName -PackageKeyNamePart $parts[1])) {
            $result.Valid = $true
            $result.Scope = $parts[0]
            $result.Package = $parts[1]
            $result.PackageSpec = "$($parts[0])/$($parts[1])"
        }
        else {
            throw "scope '$($parts[0])' is not a valid scope name or part '$($parts[1])' is not a valid package name."
        }
    }

    if ($result.Valid -ne $true) {
        throw "Split-PackageKeyName failed to parse '$($PackageKeyName)'."
    }

    return $result
}

function Split-PackageLockPackageName {
    Param(
        [Parameter(Mandatory)]
        [PSCustomObject]
        $Value
    )

    $packageKeyName = $Value.PackageKeyName
    if ([string]::IsNullOrEmpty($packageKeyName)) {
        throw "No value on the 'PackageKeyName' property."
    }
    $packageVersion = $Value.version
    if ([string]::IsNullOrEmpty($packageVersion)) {
        throw "No value on the 'version' property."
    }
    if (!(Test-NpmPackageVersionString -Version $Value.version)) {
        throw "Version '$($Value.version)' string failed to pass validation."
    }

    $packageKeySplit = Split-PackageKeyName -PackageKeyName $packageKeyName
    Write-Debug "package: $($packageKeySplit.PackageSpec) $($packageVersion)"
    $Value | Add-Member -NotePropertyName 'PackageKeySplit' -NotePropertyValue $packageKeySplit

    $packageResolvedUrl = $Value.resolved
    if ([string]::IsNullOrEmpty($packageResolvedUrl)) {
        throw "No value on the 'resolved' property."
    }
    $uriObject = New-Object System.Uri($Value.resolved)
    if (!($uriObject.Segments)) {
        throw "Failed to parse $($packageResolvedUrl) into segments."
    }
    if ($uriObject.Segments.Count -le 0) {
        throw "The URL $($packageResolvedUrl) has zero segments."
    }
    #$lastSegment = $uriObject.Segments[-1]
    #Write-Debug "  resource: $($lastSegment)"
    return $Value
}

function Get-PackageListFromPackageLock { # Get back a list of things we can iterate
    Param(
        [Parameter(Mandatory)]
        [PSCustomObject]
        $PackageLock
    )

    if (!($PackageLock.Value)) {
        throw "PackageLock object is missing the 'Value' property."
    }

    # Notes on v1 lock files
    # - The packages are listed under: "dependencies"
    # - There's no "node_modules" layer within the keys
    # - Might have to do dependencies of dependencies
    $lockfileVersion = $PackageLock.Value.lockfileVersion
    if ([string]::IsNullOrEmpty($lockfileVersion)) {
        throw "No value on the 'lockfileVersion' property."
    }
    $supportedLockFileVersions = @(2, 3)
    if ($supportedLockFileVersions -notcontains $lockfileVersion) {
        throw "We do not support support lockfileVersion '$($lockfileVersion)'."
    }

    $packages = $PackageLock.Value.packages
    if (!($packages)) {
        throw "PackageLock.Value.packages is not found on the object."
    }

    $result = @()
    $packages.psobject.Properties | ForEach-Object {
        #Write-Debug "Key: $($_.Name), Value: $($_.Value)"
        if (!($_.Name -eq "(root)")) {
            $item = $_.Value
            $item | Add-Member -NotePropertyName 'PackageKeyName' -NotePropertyValue $_.Name
            $item = Split-PackageLockPackageName -Value $item
            $result += $item            
        }
    }    
    return $result
}

function Get-NpmPackageViewCacheFileName {
    Param(
        [Parameter(Mandatory)]
        [string]
        $PackageSpec
    )

    $packageSplit = Split-PackageKeyName -PackageKeyName $PackageSpec

    if (!(Test-StringIsNpmPackageName -PackageKeyNamePart $packageSplit.Package)) {
        throw "Package name '$($packageSplit.Package)' string failed to pass validation."
    }

    $cacheFileName = "$($packageSplit.Package).json"

    return $cacheFileName
}

function Get-NpmPackageViewCacheFilePath {
    Param(
        [Parameter(Mandatory)]
        [string]
        $PackageSpec
    )

    $cacheDirPath = $CacheDirectory

    $packageSplit = Split-PackageKeyName -PackageKeyName $PackageSpec
    if (!([string]::IsNullOrEmpty($packageSplit.Scope))) {
        $cacheDirPath = Join-Path -Path $cacheDirPath -ChildPath $packageSplit.Scope
    }

    $cacheFileName = Get-NpmPackageViewCacheFileName -PackageSpec $PackageSpec
    $cacheFilePath = Join-Path -Path $cacheDirPath -ChildPath $cacheFileName

    return $cacheFilePath
}

function Update-NpmPackageViewCacheFile {
    Param(
        [Parameter(Mandatory)]
        [string]
        $PackageSpec,

        [Parameter(Mandatory)]
        [object]
        $Value
    )

    if (-not (Test-Path $CacheDirectory -PathType Container)) {
        $null = New-Item -Path $CacheDirectory -ItemType Directory
    }
    
    $cacheDirPath = $CacheDirectory
    if (-not (Test-Path $cacheDirPath -PathType Container)) {
        $null = New-Item -Path $cacheDirPath -ItemType Directory
    }
    
    $packageSplit = Split-PackageKeyName -PackageKeyName $PackageSpec
    if (!([string]::IsNullOrEmpty($packageSplit.Scope))) {
        $cacheDirPath = Join-Path -Path $cacheDirPath -ChildPath $packageSplit.Scope
        if (-not (Test-Path $cacheDirPath -PathType Container)) {
            $null = New-Item -Path $cacheDirPath -ItemType Directory
        }
    }

    $cacheFilePath = Get-NpmPackageViewCacheFilePath -PackageSpec $PackageSpec

    $cacheEntry = [PSCustomObject]@{
        PackageSpec = $PackageSpec
        Scope = $packageSplit.Scope
        Package = $packageSplit.Package
        Value = $Value
    }

    #Write-Debug "write: $($cacheFilePath)"
    $cacheEntry | ConvertTo-Json -Depth 25 | Out-File -Encoding UTF8 -FilePath $cacheFilePath

    return $cacheEntry
}

function Get-NpmPackageViewCacheEntry {
    Param(
        [Parameter(Mandatory)]
        [string]
        $PackageSpec
    )

    $cacheFilePath = Get-NpmPackageViewCacheFilePath -PackageSpec $PackageSpec
    if ($null -ne $cacheFilePath) {
        if (-not (Test-Path $cacheFilePath -PathType Leaf)) {
            return $null
        }
        $cacheEntry = Get-Content -Path $cacheFilePath -Raw | ConvertFrom-Json
        return $cacheEntry
    }
    return $null  
}

function Get-NpmPackageVersionEntry {
    Param(
        [Parameter(Mandatory)]
        [string]
        $PackageSpec,

        [Parameter(Mandatory)]
        [string]
        $Version
    )

    Write-Debug "pkg: $($PackageSpec) ver: $($Version)"
    $publishDateString = $null
    $viewCacheEntry = Get-NpmPackageViewCacheEntry -PackageSpec $PackageSpec
    if ($null -ne $viewCacheEntry) {
        #$values = $viewCacheEntry.Value
        #Write-Debug "value: $($values)"
        #Write-Debug "created date: $($values.created)"
        #Write-Debug "modified date: $($values.modified)"
        $publishDateString = $viewCacheEntry.Value.$Version
        Write-Debug "cached date: $($publishDateString)"
    }
    if ($null -eq $publishDateString) {
        $packageSplit = Split-PackageKeyName -PackageKeyName $PackageSpec
        Write-Debug "npm view $($packageSplit.PackageSpec) time --json"
        $npmCommand = Get-NPMCommandPath
        $packageVersionsJsonString = (& $npmCommand view $packageSplit.PackageSpec time --json)
        $packageVersions = $packageVersionsJsonString | ConvertFrom-Json -AsHashtable
        $viewCacheEntry = Update-NpmPackageViewCacheFile -PackageSpec $PackageSpec -Value $packageVersions
        $publishDateString = $viewCacheEntry.Value[$Version]
        $global:CacheMiss++
    }
    else {
        $global:CacheHit++
    }    

    Write-Debug "publish-date: $($publishDateString)"

    if ($null -ne $publishDateString) {
        $result = [PSCustomObject]@{
            PackageSpec = $PackageSpec
            Scope = $viewCacheEntry.Scope
            Package = $viewCacheEntry.Package
            Version = $Version
            PublishDate = $publishDateString
        }
        return $result
    }
    return $null
}

function Get-NpmPackagePublishDate {
    Param(
        [Parameter(Mandatory)]
        [string]
        $PackageSpec,

        [Parameter(Mandatory)]
        [string]
        $Version
    )

    $packageSplit = Split-PackageKeyName -PackageKeyName $PackageSpec

    $cacheResult = Get-NpmPackageVersionEntry -PackageSpec $PackageSpec -Version $Version

    #Write-Debug "$cacheResult"
    
    $result = [PSCustomObject]@{
        Valid = $false
        PackageSpec = $PackageSpec
        Scope = $packageSplit.Scope
        Package = $packageSplit.Package
        Version = $Version
        PublishDate = $cacheResult.PublishDate
    }

    return $result
}

Write-Host "Starting..."

$npmCommand = Get-NPMCommandPath
Write-Debug "npm path: $($npmCommand)"

$packageLock = Get-PackageLock -ProjectDirectory $ProjectDirectory
Write-Debug "loaded package-lock for $($packageLock.value.name) $($packageLock.value.version)"

$packages = Get-PackageListFromPackageLock -PackageLock $packageLock | Sort-Object {Get-Random}
Write-Debug "packages: $($packages.Count)"

#$packages | Format-Table -Property PackageKeyName, @{Label='PackageSpec'; Expression={$_.PackageKeySplit.PackageSpec}}, version

$newestPublishDate = [System.DateTimeOffset]::new(1970, 1, 1, 0, 0, 0, [TimeSpan]::FromHours(0)) # some time way in the past

Write-Host "Getting publication dates for all package versions..."

$ActivityMessage = "Retrieving..."
$count = 1
$exportRecords = @()
foreach ($package in $packages) {
    $PercentComplete = ($count / @($packages).count * 100)
    $pctComplete = ([Math]::Floor($PercentComplete)).ToString("N0").PadLeft(3, ' ') + "%"
    $StatusMessage = ("{0}: Processing {1} of {2} - {3}" -f $pctComplete, $count, @($packages).Count, $package.PackageKeySplit.PackageSpec)
    Write-Progress -Activity $ActivityMessage -Status $StatusMessage -PercentComplete $PercentComplete
    $count++

    $entry = Get-NpmPackagePublishDate -PackageSpec $package.PackageKeySplit.PackageSpec -Version $package.version

    if ($null -eq $entry) {
        Write-Warning "Unable to get entry for: $($package.PackageKeySplit.PackageSpec) version: $($package.version)"
        continue
    }

    if ($null -eq $entry.PublishDate) {
        Write-Warning "Unable to get publish date for: $($package.PackageKeySplit.PackageSpec) version: $($package.version)"
    }
    else {
        $publishDate = [System.DateTimeOffset]$entry.PublishDate
        Write-Debug "$($package.PackageKeySplit.PackageSpec) ver: $($package.version) uploaded: $($publishDate)"
        if ($publishDate -gt $newestPublishDate) { $newestPublishDate = $publishDate }
    }

    $exportRecord = [PSCustomObject]@{
        PackageSpec = $entry.PackageSpec
        Scope = $entry.Scope
        Package = $entry.Package
        Version = $entry.Version
        PublishDate = $entry.PublishDate
    }
    $exportRecords += $exportRecord
}

Write-Debug "newestPublishDate: $($newestPublishDate)"
$timeDifference = ([DateTimeOffset]::Now) - $newestPublishDate
$daysSinceLatestPublishDate = [int]($timeDifference.TotalDays)

Write-Host "Latest publish date: $($newestPublishDate.ToString("u"))"
Write-Host "Days since latest publish date: $($daysSinceLatestPublishDate)"

Write-Debug "CacheHit: $($global:CacheHit)"
Write-Debug "CacheMiss: $($global:CacheMiss)"

$exportFileName = "npm-check-package-lock-publish-dates.csv"
$exportFileDirectory = "./"
$exportFilePath = Join-Path -Path $exportFileDirectory -ChildPath $exportFileName
Write-Host "Export results to: $($exportFilePath)"
$exportRecords | Sort-Object -Property PackageSpec | Export-CSV -nti -Encoding UTF8BOM -Path $exportFilePath

if ($MinimumPublishAgeDays -gt $daysSinceLatestPublishDate) {
    Write-Error "Found NPM packages published $($daysSinceLatestPublishDate) ago, below the threshold of $($MinimumPublishAgeDays) days." -ErrorAction Stop
}

Write-Host "Complete."
