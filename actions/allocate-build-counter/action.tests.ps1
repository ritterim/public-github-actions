#TODO: This file is getting too large, break it down into smaller Pester test files

BeforeAll {
    # Dot-source the action script to load functions (with -NoRun to skip main logic)
    . $PSScriptRoot/action.ps1 -NoRun

    # Helper to create a bare "origin" repo and a working clone seeded with one commit
    function New-TestGitRepo {
        param([string] $Prefix = 'pester')
        $rand = [System.IO.Path]::GetRandomFileName() -replace '\..*', ''
        $tempBase = [System.IO.Path]::GetTempPath()
        $bareDir  = Join-Path $tempBase "${Prefix}-bare-${rand}.git"
        $initDir  = Join-Path $tempBase "${Prefix}-init-${rand}"
        $workDir  = Join-Path $tempBase "${Prefix}-work-${rand}"

        # Create bare repo (acts as origin)
        & git init --bare $bareDir 2>&1 | Out-Null

        # Clone to init dir, create one commit, push it, then remove init dir
        & git clone $bareDir $initDir 2>&1 | Out-Null
        & git -C $initDir config user.email 'pester@test.local' 2>&1 | Out-Null
        & git -C $initDir config user.name 'Pester' 2>&1 | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $initDir '.gitkeep'), '')
        & git -C $initDir add '.gitkeep' 2>&1 | Out-Null
        & git -C $initDir commit -m 'Initial commit for tests' 2>&1 | Out-Null
        & git -C $initDir push origin HEAD 2>&1 | Out-Null
        Remove-Item $initDir -Recurse -Force

        # Clone again for use as working copy in tests
        & git clone $bareDir $workDir 2>&1 | Out-Null
        & git -C $workDir config user.email 'pester@test.local' 2>&1 | Out-Null
        & git -C $workDir config user.name 'Pester' 2>&1 | Out-Null

        return @{
            BareDir = $bareDir
            WorkDir = $workDir
        }
    }

    function Remove-TestGitRepo {
        param([hashtable] $Repo)
        Remove-Item $Repo.BareDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $Repo.WorkDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Test-ValidCounterKey' {
    It 'accepts valid alphanumeric counter_key' {
        Test-ValidCounterKey -CounterKey 'repo' | Should -Be $true
        Test-ValidCounterKey -CounterKey 'build123' | Should -Be $true
        Test-ValidCounterKey -CounterKey 'a' | Should -Be $true
    }

    It 'accepts 32-character counter_key (max length)' {
        $counterKey32 = 'a' * 32
        Test-ValidCounterKey -CounterKey $counterKey32 | Should -Be $true
    }

    It 'rejects empty counter_key' {
        { Test-ValidCounterKey -CounterKey '' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects counter_key longer than 32 chars' {
        $counterKey33 = 'a' * 33
        { Test-ValidCounterKey -CounterKey $counterKey33 -ErrorAction Stop } | Should -Throw
    }

    It 'rejects counter_key with special characters' {
        { Test-ValidCounterKey -CounterKey 'repo-app' -ErrorAction Stop } | Should -Throw
        { Test-ValidCounterKey -CounterKey 'repo_app' -ErrorAction Stop } | Should -Throw
        { Test-ValidCounterKey -CounterKey 'repo.app' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects counter_key with spaces' {
        { Test-ValidCounterKey -CounterKey 'repo app' -ErrorAction Stop } | Should -Throw
    }
}

Describe 'Test-ValidMaxRetries' {
    It 'accepts valid retry counts' {
        Test-ValidMaxRetries -MaxRetries 1 | Should -Be $true
        Test-ValidMaxRetries -MaxRetries 25 | Should -Be $true
        Test-ValidMaxRetries -MaxRetries 100 | Should -Be $true
    }

    It 'rejects zero retries' {
        { Test-ValidMaxRetries -MaxRetries 0 -ErrorAction Stop } | Should -Throw
    }

    It 'rejects negative retries' {
        { Test-ValidMaxRetries -MaxRetries -1 -ErrorAction Stop } | Should -Throw
    }

    It 'rejects retries over 100' {
        { Test-ValidMaxRetries -MaxRetries 101 -ErrorAction Stop } | Should -Throw
    }
}

Describe 'Test-ValidGitHubOwner' {
    It 'accepts valid GitHub owners' {
        Test-ValidGitHubOwner -Owner 'myorg' | Should -Be $true
        Test-ValidGitHubOwner -Owner 'my-org' | Should -Be $true
        Test-ValidGitHubOwner -Owner 'org123' | Should -Be $true
        Test-ValidGitHubOwner -Owner 'a' | Should -Be $true
    }

    It 'accepts 39-character owner (max length)' {
        $owner39 = 'a' * 39
        Test-ValidGitHubOwner -Owner $owner39 | Should -Be $true
    }

    It 'rejects empty owner' {
        { Test-ValidGitHubOwner -Owner '' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects owner longer than 39 chars' {
        $owner40 = 'a' * 40
        { Test-ValidGitHubOwner -Owner $owner40 -ErrorAction Stop } | Should -Throw
    }

    It 'rejects owner starting with hyphen' {
        { Test-ValidGitHubOwner -Owner '-org' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects owner ending with hyphen' {
        { Test-ValidGitHubOwner -Owner 'org-' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects owner with special characters' {
        { Test-ValidGitHubOwner -Owner 'org_name' -ErrorAction Stop } | Should -Throw
        { Test-ValidGitHubOwner -Owner 'org.name' -ErrorAction Stop } | Should -Throw
        { Test-ValidGitHubOwner -Owner 'org@name' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects owner with spaces' {
        { Test-ValidGitHubOwner -Owner 'org name' -ErrorAction Stop } | Should -Throw
    }
}

Describe 'Test-ValidRepositoryName' {
    It 'accepts valid repository names' {
        Test-ValidRepositoryName -Name 'my-repo' | Should -Be $true
        Test-ValidRepositoryName -Name 'my_repo' | Should -Be $true
        Test-ValidRepositoryName -Name 'my.repo' | Should -Be $true
        Test-ValidRepositoryName -Name 'repo123' | Should -Be $true
        Test-ValidRepositoryName -Name 'a' | Should -Be $true
        Test-ValidRepositoryName -Name '_repo' | Should -Be $true
    }

    It 'accepts 255-character name (max length)' {
        $name255 = 'a' * 255
        Test-ValidRepositoryName -Name $name255 | Should -Be $true
    }

    It 'rejects empty name' {
        { Test-ValidRepositoryName -Name '' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects name longer than 255 chars' {
        $name256 = 'a' * 256
        { Test-ValidRepositoryName -Name $name256 -ErrorAction Stop } | Should -Throw
    }

    It 'rejects name with special characters' {
        { Test-ValidRepositoryName -Name 'repo@name' -ErrorAction Stop } | Should -Throw
        { Test-ValidRepositoryName -Name 'repo#name' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects name with spaces' {
        { Test-ValidRepositoryName -Name 'repo name' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects name starting with a dot' {
        { Test-ValidRepositoryName -Name '.foo' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects name starting with a hyphen' {
        { Test-ValidRepositoryName -Name '-foo' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects bare dot / double-dot' {
        { Test-ValidRepositoryName -Name '.' -ErrorAction Stop } | Should -Throw
        { Test-ValidRepositoryName -Name '..' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects consecutive dots inside the name' {
        { Test-ValidRepositoryName -Name 'foo..bar' -ErrorAction Stop } | Should -Throw
    }
}

Describe 'Get-ResolvedOrganization' {
    It 'uses GITHUB_REPOSITORY_OWNER env var when set' {
        $env:GITHUB_REPOSITORY_OWNER = 'envorg'
        $info = Get-ResolvedOrganization
        $info.Value | Should -Be 'envorg'
        $info.Source | Should -Be 'GITHUB_REPOSITORY_OWNER env var'
    }

    It 'uses default fallback when env is empty' {
        $env:GITHUB_REPOSITORY_OWNER = ''
        $info = Get-ResolvedOrganization
        $info.Value | Should -Be 'local-org'
        $info.Source | Should -Be 'fallback default'
    }

    It 'does not validate inside the helper - returns raw value even when invalid' {
        $env:GITHUB_REPOSITORY_OWNER = 'invalid-org-'
        $info = Get-ResolvedOrganization
        $info.Value | Should -Be 'invalid-org-'
    }
}

Describe 'Get-ResolvedRepository' {
    It 'extracts repo from GITHUB_REPOSITORY when env is set' {
        $env:GITHUB_REPOSITORY = 'org/envrepo'
        $info = Get-ResolvedRepository
        $info.Value | Should -Be 'envrepo'
        $info.Source | Should -Be 'GITHUB_REPOSITORY env var'
    }

    It 'uses default fallback when env is empty' {
        $env:GITHUB_REPOSITORY = ''
        $info = Get-ResolvedRepository
        $info.Value | Should -Be 'local-repo'
        $info.Source | Should -Be 'fallback default'
    }

    It 'does not validate inside the helper - returns raw value even when invalid' {
        $env:GITHUB_REPOSITORY = 'org/repo@invalid'
        $info = Get-ResolvedRepository
        $info.Value | Should -Be 'repo@invalid'
    }
}

Describe 'Test-ValidGitHubServerUrl' {
    It 'accepts the canonical github.com URL' {
        Test-ValidGitHubServerUrl -Url 'https://github.com' | Should -Be $true
    }

    # Each rejection below corresponds to an attack pattern documented in the
    # block comment above Test-ValidGitHubServerUrl. The strict equality check
    # is what enforces these; the cases below pin the behavior.

    It 'rejects userinfo present - credential confusion / auth masquerade' {
        { Test-ValidGitHubServerUrl -Url 'https://user:pass@github.com' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects multiple @ characters - host-extraction ambiguity' {
        { Test-ValidGitHubServerUrl -Url 'https://a@b@github.com' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects port confusion via userinfo masquerade - looks like github.com but points elsewhere' {
        { Test-ValidGitHubServerUrl -Url 'https://github.com:443@evil.com' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects implicit empty auth - credential placeholder confuses parser' {
        { Test-ValidGitHubServerUrl -Url 'https://:@github.com' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects empty host - would fall through to local URL resolution' {
        { Test-ValidGitHubServerUrl -Url 'https:///foo' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects percent-encoded host - decoding mismatch between validator and consumer' {
        { Test-ValidGitHubServerUrl -Url 'https://github%2ecom@evil.com' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects IDN / Unicode homograph - visual lookalike resolving elsewhere' {
        { Test-ValidGitHubServerUrl -Url "https://g$([char]0x00EC)thub.com" -ErrorAction Stop } | Should -Throw
    }

    It 'rejects trailing whitespace / control chars - header-injection risk' {
        { Test-ValidGitHubServerUrl -Url "https://github.com`r`n" -ErrorAction Stop } | Should -Throw
    }

    It 'rejects fragment - parser desync between validator and git' {
        { Test-ValidGitHubServerUrl -Url 'https://github.com#x' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects query string - same parser desync risk as fragments' {
        { Test-ValidGitHubServerUrl -Url 'https://github.com?x=y' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects path traversal - escape from expected path layout' {
        { Test-ValidGitHubServerUrl -Url 'https://github.com/../' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects case-variant scheme/host - case-fold bypass risk' {
        { Test-ValidGitHubServerUrl -Url 'HTTPS://GITHUB.COM' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects port :0 - malformed shape used to confuse parsers' {
        { Test-ValidGitHubServerUrl -Url 'https://github.com:0' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects trailing .git on bare server URL - parsed as different host' {
        { Test-ValidGitHubServerUrl -Url 'https://github.com.git' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects trailing slash - strict equality (no normalization)' {
        { Test-ValidGitHubServerUrl -Url 'https://github.com/' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects empty URL' {
        { Test-ValidGitHubServerUrl -Url '' -ErrorAction Stop } | Should -Throw
    }

    It 'includes the Source label in the error message for troubleshooting' {
        try {
            Test-ValidGitHubServerUrl -Url 'https://evil.com' -Source 'GITHUB_SERVER_URL env var' -ErrorAction Stop
        }
        catch {
            $_.ToString() | Should -Match 'GITHUB_SERVER_URL env var'
        }
    }
}

Describe 'Test-ValidGitCounterRepoUrl' {
    It 'accepts file:// URLs (test fixture seam, no token attached)' {
        Test-ValidGitCounterRepoUrl -Url 'file:///tmp/anything' | Should -Be $true
        Test-ValidGitCounterRepoUrl -Url 'file:///tmp/path/with/../traversal' | Should -Be $true
    }

    It 'accepts https://github.com/<owner>/<repo>.git URLs' {
        Test-ValidGitCounterRepoUrl -Url 'https://github.com/org/repo.git' | Should -Be $true
    }

    It 'rejects http:// (no TLS)' {
        { Test-ValidGitCounterRepoUrl -Url 'http://github.com/org/repo.git' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects other hosts' {
        { Test-ValidGitCounterRepoUrl -Url 'https://evil.com/org/repo.git' -ErrorAction Stop } | Should -Throw
    }

    It 'rejects empty URL' {
        { Test-ValidGitCounterRepoUrl -Url '' -ErrorAction Stop } | Should -Throw
    }
}

Describe 'Get-NextBuildNumber' {
    BeforeAll {
        $script:gcbnRepo = New-TestGitRepo -Prefix 'gcbn'
    }

    AfterAll {
        Remove-TestGitRepo $script:gcbnRepo
    }

    BeforeEach {
        # Clean up all local and remote tags from previous tests (operate via -C on the work dir)
        $work = $script:gcbnRepo.WorkDir
        $localTags = & git -C $work tag -l 2>&1
        if ($localTags) {
            $localTags | ForEach-Object { & git -C $work tag -d $_ 2>&1 | Out-Null }
        }
        $remoteTags = & git -C $work ls-remote --tags origin 2>&1 | Where-Object { $_ -match 'refs/tags/' } | ForEach-Object { ($_ -split '\s+')[1] -replace '\^\{\}$' }
        if ($remoteTags) {
            $remoteTags | ForEach-Object { & git -C $work push origin --delete $_ 2>&1 | Out-Null }
        }
    }

    It 'returns NextNumber=1 and CurrentTag=$null when no tags exist' {
        $result = Get-NextBuildNumber -RepoPath $script:gcbnRepo.WorkDir -TagPrefix 'gcbn-empty-'
        $result | Should -BeOfType [hashtable]
        $result.NextNumber | Should -Be 1
        $result.CurrentTag | Should -BeNull
    }

    It 'returns correct NextNumber and CurrentTag when tags exist on remote' {
        $work = $script:gcbnRepo.WorkDir
        $prefix = 'gcbn-existing-'
        # Create and push tags
        & git -C $work tag "${prefix}3" 2>&1 | Out-Null
        & git -C $work tag "${prefix}7" 2>&1 | Out-Null
        & git -C $work tag "${prefix}15" 2>&1 | Out-Null
        & git -C $work push origin "refs/tags/${prefix}3" "refs/tags/${prefix}7" "refs/tags/${prefix}15" 2>&1 | Out-Null
        # Delete local tags so fetch is required to see them
        & git -C $work tag -d "${prefix}3" "${prefix}7" "${prefix}15" 2>&1 | Out-Null

        $result = Get-NextBuildNumber -RepoPath $work -TagPrefix $prefix
        $result.CurrentTag | Should -Be "${prefix}15"
        $result.NextNumber | Should -Be 16
    }

    It 'wraps around to 0 after 65535' {
        $work = $script:gcbnRepo.WorkDir
        $prefix = 'gcbn-wrap-'
        & git -C $work tag "${prefix}65535" 2>&1 | Out-Null
        & git -C $work push origin "refs/tags/${prefix}65535" 2>&1 | Out-Null
        & git -C $work tag -d "${prefix}65535" 2>&1 | Out-Null

        $result = Get-NextBuildNumber -RepoPath $work -TagPrefix $prefix
        $result.CurrentTag | Should -Be "${prefix}65535"
        $result.NextNumber | Should -Be 0
    }

    It 'self-heals: ignores foreign tags whose post-prefix is non-numeric' {
        $work = $script:gcbnRepo.WorkDir
        $prefix = 'gcbn-heal-'
        & git -C $work tag "${prefix}5" 2>&1 | Out-Null
        & git -C $work tag "${prefix}foo" 2>&1 | Out-Null
        & git -C $work tag "${prefix}10-bad" 2>&1 | Out-Null
        & git -C $work push origin "refs/tags/${prefix}5" "refs/tags/${prefix}foo" "refs/tags/${prefix}10-bad" 2>&1 | Out-Null
        & git -C $work tag -d "${prefix}5" "${prefix}foo" "${prefix}10-bad" 2>&1 | Out-Null

        $result = Get-NextBuildNumber -RepoPath $work -TagPrefix $prefix
        $result.CurrentTag | Should -Be "${prefix}5"
        $result.NextNumber | Should -Be 6
    }

    It 'self-heals: returns NextNumber=1 when only foreign tags exist' {
        $work = $script:gcbnRepo.WorkDir
        $prefix = 'gcbn-only-foreign-'
        & git -C $work tag "${prefix}abc" 2>&1 | Out-Null
        & git -C $work push origin "refs/tags/${prefix}abc" 2>&1 | Out-Null
        & git -C $work tag -d "${prefix}abc" 2>&1 | Out-Null

        $result = Get-NextBuildNumber -RepoPath $work -TagPrefix $prefix
        $result.CurrentTag | Should -BeNull
        $result.NextNumber | Should -Be 1
    }

    It 'calculates rollover correctly at 65535 (pure arithmetic)' {
        $nextNum = (65535 + 1) % 65536
        $nextNum | Should -Be 0
    }
}

Describe 'Push-BuildNumberTag' {
    BeforeAll {
        $script:pbtRepo = New-TestGitRepo -Prefix 'pbt'

        # Create a second clone to simulate a competing worker
        $rand = [System.IO.Path]::GetRandomFileName() -replace '\..*', ''
        $script:otherWorkerDir = Join-Path ([System.IO.Path]::GetTempPath()) "pbt-other-${rand}"
        & git clone $script:pbtRepo.BareDir $script:otherWorkerDir 2>&1 | Out-Null
        & git -C $script:otherWorkerDir config user.email 'pester@test.local' 2>&1 | Out-Null
        & git -C $script:otherWorkerDir config user.name 'Pester' 2>&1 | Out-Null
    }

    AfterAll {
        Remove-TestGitRepo $script:pbtRepo
        Remove-Item $script:otherWorkerDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns $true and leaves tag on remote when push succeeds' {
        $work = $script:pbtRepo.WorkDir
        $tag = 'pbt-success-1'

        $result = Push-BuildNumberTag -RepoPath $work -NewTag $tag

        $result | Should -Be $true

        # Tag should exist on remote
        $remoteTags = & git -C $work ls-remote --tags origin 2>&1 | Where-Object { $_ -match [regex]::Escape($tag) }
        $remoteTags | Should -Not -BeNullOrEmpty

        # Tag should still exist locally
        $localTag = & git -C $work tag -l $tag 2>&1
        $localTag | Should -Be $tag
    }

    It 'returns $false and removes local tag when push is rejected due to conflict' {
        $work = $script:pbtRepo.WorkDir
        $tag = 'pbt-conflict-1'

        # Other worker pushes this tag first, pointing to base commit
        & git -C $script:otherWorkerDir tag $tag 2>&1 | Out-Null
        & git -C $script:otherWorkerDir push origin "refs/tags/${tag}" 2>&1 | Out-Null

        # Our worker makes a new commit so the tag will point to a different SHA
        [System.IO.File]::WriteAllText((Join-Path $work 'pbt-extra'), 'conflict test')
        & git -C $work add 'pbt-extra' 2>&1 | Out-Null
        & git -C $work commit -m 'add file for conflict test' 2>&1 | Out-Null

        $result = Push-BuildNumberTag -RepoPath $work -NewTag $tag

        $result | Should -Be $false

        # Local tag must have been cleaned up
        $localTag = & git -C $work tag -l $tag 2>&1
        $localTag | Should -BeNullOrEmpty

        # Remote still has the other worker's tag
        $remoteTags = & git -C $work ls-remote --tags origin 2>&1 | Where-Object { $_ -match [regex]::Escape($tag) }
        $remoteTags | Should -Not -BeNullOrEmpty
    }
}

Describe 'Remove-OldBuildNumberTags' {
    BeforeAll {
        $script:robtRepo = New-TestGitRepo -Prefix 'robt'
    }

    AfterAll {
        Remove-TestGitRepo $script:robtRepo
    }

    It 'deletes old prefixed tags on remote but keeps the new tag' {
        $work = $script:robtRepo.WorkDir
        $prefix = 'robt-cleanup-'
        $newTag = "${prefix}3"

        # Push several tags with the prefix
        & git -C $work tag "${prefix}1" 2>&1 | Out-Null
        & git -C $work tag "${prefix}2" 2>&1 | Out-Null
        & git -C $work tag "${prefix}3" 2>&1 | Out-Null
        & git -C $work push origin "refs/tags/${prefix}1" "refs/tags/${prefix}2" "refs/tags/${prefix}3" 2>&1 | Out-Null

        # Verify setup: all 3 tags on remote
        $beforeTags = & git -C $work ls-remote --tags origin 2>&1 | Where-Object { $_ -match [regex]::Escape($prefix) }
        $beforeTags | Should -HaveCount 3

        Remove-OldBuildNumberTags -RepoPath $work -TagPrefix $prefix -NewTag $newTag

        # Verify: only newTag remains on remote
        $afterTags = & git -C $work ls-remote --tags origin 2>&1 | Where-Object { $_ -match [regex]::Escape($prefix) }
        $afterTags | Should -HaveCount 1
        $afterTags | Where-Object { $_ -like "*$newTag" } | Should -HaveCount 1
    }

    It 'does nothing when only the new tag exists' {
        $work = $script:robtRepo.WorkDir
        $prefix = 'robt-sole-'
        $newTag = "${prefix}1"

        & git -C $work tag $newTag 2>&1 | Out-Null
        & git -C $work push origin "refs/tags/${newTag}" 2>&1 | Out-Null

        { Remove-OldBuildNumberTags -RepoPath $work -TagPrefix $prefix -NewTag $newTag } | Should -Not -Throw

        $remoteTags = & git -C $work ls-remote --tags origin 2>&1 | Where-Object { $_ -match [regex]::Escape($prefix) }
        $remoteTags | Should -HaveCount 1
    }

    It 'does not delete tags with a different prefix' {
        $work = $script:robtRepo.WorkDir
        $prefix      = 'robt-nocrss-'
        $otherPrefix = 'robt-other-'
        $newTag      = "${prefix}2"

        & git -C $work tag "${prefix}1" 2>&1 | Out-Null
        & git -C $work tag "${prefix}2" 2>&1 | Out-Null
        & git -C $work tag "${otherPrefix}99" 2>&1 | Out-Null
        & git -C $work push origin "refs/tags/${prefix}1" "refs/tags/${prefix}2" "refs/tags/${otherPrefix}99" 2>&1 | Out-Null

        Remove-OldBuildNumberTags -RepoPath $work -TagPrefix $prefix -NewTag $newTag

        # Other prefix tag must still exist on remote
        $otherTag = & git -C $work ls-remote --tags origin 2>&1 | Where-Object { $_ -match [regex]::Escape($otherPrefix) }
        $otherTag | Should -HaveCount 1
    }

    It 'self-heals: does not delete foreign (non-numeric post-prefix) tags' {
        $work = $script:robtRepo.WorkDir
        $prefix = 'robt-heal-'
        $newTag = "${prefix}5"

        & git -C $work tag "${prefix}1" 2>&1 | Out-Null
        & git -C $work tag "${prefix}foo" 2>&1 | Out-Null
        & git -C $work tag "${prefix}5" 2>&1 | Out-Null
        & git -C $work push origin "refs/tags/${prefix}1" "refs/tags/${prefix}foo" "refs/tags/${prefix}5" 2>&1 | Out-Null

        Remove-OldBuildNumberTags -RepoPath $work -TagPrefix $prefix -NewTag $newTag

        $afterTags = & git -C $work ls-remote --tags origin 2>&1 | Where-Object { $_ -match [regex]::Escape($prefix) } | ForEach-Object { ($_ -split '\s+')[1] }
        $afterTags | Should -Contain "refs/tags/${prefix}foo"
        $afterTags | Should -Contain "refs/tags/${prefix}5"
        $afterTags | Should -Not -Contain "refs/tags/${prefix}1"
    }
}

Describe 'Set-GitHubOutput' {
    It 'writes outputs to GITHUB_OUTPUT file' {
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            $env:GITHUB_OUTPUT = $tempFile
            Set-GitHubOutput @{ build_number = 42; tag = 'test-42' }

            $content = Get-Content $tempFile
            $content | Should -Contain 'build_number=42'
            $content | Should -Contain 'tag=test-42'
        }
        finally {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    }

    It 'handles missing GITHUB_OUTPUT gracefully' {
        $env:GITHUB_OUTPUT = ''
        { Set-GitHubOutput @{ build_number = 42 } } | Should -Not -Throw
    }
}

Describe 'Initialize-CounterRepository' {
    BeforeAll {
        $script:icrRepo = New-TestGitRepo -Prefix 'icr'
        $rand = [System.IO.Path]::GetRandomFileName() -replace '\..*', ''
        $script:destPath = Join-Path ([System.IO.Path]::GetTempPath()) "icr-dest-${rand}"
        $script:icrCwdBefore = (Get-Location).Path
    }

    AfterAll {
        Remove-TestGitRepo $script:icrRepo
        Remove-Item $script:destPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'clones the repo and returns the dest path without mutating cwd' {
        $fileUrl = "file://$($script:icrRepo.BareDir)"

        $returned = Initialize-CounterRepository -Owner 'unused' -Name 'unused' -Token 'unused' `
            -RepoUrl $fileUrl -DestPath $script:destPath

        $returned | Should -Be $script:destPath
        (Get-Location).Path | Should -Be $script:icrCwdBefore
        (Join-Path $script:destPath '.git') | Should -Exist
    }

    It 'removes existing dest path before cloning (idempotent)' {
        $fileUrl = "file://$($script:icrRepo.BareDir)"

        $returned = Initialize-CounterRepository -Owner 'unused' -Name 'unused' -Token 'unused' `
            -RepoUrl $fileUrl -DestPath $script:destPath

        $returned | Should -Be $script:destPath
        (Get-Location).Path | Should -Be $script:icrCwdBefore
    }
}

Describe 'Format-GitArgsForDisplay' {
    It 'redacts token in basic-auth URL' {
        # Use a fixture password that is obviously not a credential to avoid
        # tripping repository secret scanners on the test source itself.
        $fixturePassword = 'placeholder-test-fixture-not-a-credential'
        $redacted = Format-GitArgsForDisplay -Arguments @('clone', "https://x-access-token:${fixturePassword}@example.test/org/repo.git", '/tmp/x')
        $redacted -join ' ' | Should -Match '://x-access-token:\*\*\*@example.test'
        $redacted -join ' ' | Should -Not -Match $fixturePassword
    }

    It 'leaves token-free URLs untouched' {
        $args1 = @('fetch', '--tags', '--force')
        $redacted = Format-GitArgsForDisplay -Arguments $args1
        @($redacted) | Should -Be $args1
    }

    It 'leaves file:// URLs untouched' {
        $args1 = @('clone', 'file:///tmp/bare.git', '/tmp/x')
        $redacted = Format-GitArgsForDisplay -Arguments $args1
        @($redacted) | Should -Be $args1
    }
}

Describe 'Backoff randomization' {
    It 'uses correct bounds for random backoff (3-12s window)' {
        $min = 3000
        $max = 12001
        $max - $min | Should -Be 9001

        $rng = [System.Random]::new()
        $values = @()
        for ($i = 0; $i -lt 50; $i++) {
            $val = $rng.Next($min, $max)
            $val | Should -BeGreaterOrEqual $min
            $val | Should -BeLessThan $max
            $values += $val
        }

        $values | Select-Object -Unique | Measure-Object | Select-Object -ExpandProperty Count | Should -BeGreaterThan 1
    }
}

Describe 'Invoke-AllocateBuildCounter' {
    BeforeEach {
        $env:APP_TOKEN = ''
        $env:GITHUB_OUTPUT = ''
        $env:GITHUB_REPOSITORY_OWNER = 'org'
        $env:GITHUB_REPOSITORY = 'org/repo'
        $env:GITHUB_SERVER_URL = 'https://github.com'
        $env:COUNTER_REPO_OWNER = ''
        $env:COUNTER_REPO_NAME = ''
        $env:GITHUB_EVENT_NAME = 'pull_request'
    }

    It 'returns build_number=0 in read-only mode on pull_request event' {
        $env:GITHUB_EVENT_NAME = 'pull_request'
        Mock -CommandName 'Set-GitHubOutput'

        Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken ''

        Assert-MockCalled -CommandName 'Set-GitHubOutput' -Times 1 -ParameterFilter {
            $Outputs.build_number -eq 0 -and $Outputs.tag -match '_counters/org/repo/repo-0'
        }
    }

    It 'throws when no token AND event is not pull_request' {
        $env:GITHUB_EVENT_NAME = 'push'
        { Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken '' } | Should -Throw '*No APP_TOKEN provided outside of pull_request context*'
    }

    It 'throws when no token AND GITHUB_EVENT_NAME is empty (fail closed)' {
        $env:GITHUB_EVENT_NAME = ''
        { Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken '' } | Should -Throw '*No APP_TOKEN provided outside of pull_request context*'
    }

    It 'throws when no token AND event is workflow_dispatch' {
        $env:GITHUB_EVENT_NAME = 'workflow_dispatch'
        { Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken '' } | Should -Throw '*No APP_TOKEN provided outside of pull_request context*'
    }

    It 'prefers APP_TOKEN environment variable over parameter' {
        $testRepo = New-TestGitRepo
        $env:APP_TOKEN = 'env-token'

        Mock -CommandName 'Set-GitHubOutput' -MockWith { }

        Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken 'param-token' `
            -RepoUrl "file://$($testRepo.BareDir)" -DestPath "$($testRepo.WorkDir)-test"

        Assert-MockCalled -CommandName 'Set-GitHubOutput' -Times 1 -ParameterFilter {
            $Outputs.build_number -eq 1
        }

        Remove-TestGitRepo -Repo $testRepo
        Remove-Item "$($testRepo.WorkDir)-test" -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'successfully allocates build number on first attempt' {
        $testRepo = New-TestGitRepo
        $script:capturedOutput = @{}

        Mock -CommandName 'Set-GitHubOutput' -MockWith {
            param($Outputs)
            $script:capturedOutput = $Outputs
        }

        Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken 'test-token' `
            -RepoUrl "file://$($testRepo.BareDir)" -DestPath "$($testRepo.WorkDir)-test"

        $script:capturedOutput.build_number | Should -Be 1
        $script:capturedOutput.tag | Should -Be '_counters/org/repo/repo-1'

        Remove-TestGitRepo -Repo $testRepo
        Remove-Item "$($testRepo.WorkDir)-test" -Recurse -Force -ErrorAction SilentlyContinue
    }



    It 'returns early when counter_key validation fails' {
        $initRepoCalls = 0
        Mock -CommandName 'Initialize-CounterRepository' -MockWith {
            $initRepoCalls++
        }

        Invoke-AllocateBuildCounter -CounterKey 'invalid-key!' -MaxRetries 5 -AppToken 'test-token'

        $initRepoCalls | Should -Be 0
    }

    It 'returns early when max retries validation fails' {
        $initRepoCalls = 0
        Mock -CommandName 'Initialize-CounterRepository' -MockWith {
            $initRepoCalls++
        }

        Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 101 -AppToken 'test-token'

        $initRepoCalls | Should -Be 0
    }

    It 'returns early when GITHUB_SERVER_URL is not the canonical github.com' {
        $env:GITHUB_SERVER_URL = 'https://evil.com'
        $initRepoCalls = 0
        Mock -CommandName 'Initialize-CounterRepository' -MockWith { $initRepoCalls++ }

        Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken 'test-token'

        $initRepoCalls | Should -Be 0
    }

    It 'returns early when -RepoUrl is malformed' {
        $initRepoCalls = 0
        Mock -CommandName 'Initialize-CounterRepository' -MockWith { $initRepoCalls++ }

        Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken 'test-token' `
            -RepoUrl 'http://github.com/org/repo.git'

        $initRepoCalls | Should -Be 0
    }

    It 'returns early when COUNTER_REPO_OWNER is malformed' {
        $env:COUNTER_REPO_OWNER = 'bad-owner-'
        $initRepoCalls = 0
        Mock -CommandName 'Initialize-CounterRepository' -MockWith { $initRepoCalls++ }

        Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken 'test-token'

        $initRepoCalls | Should -Be 0
    }

    It 'returns early when COUNTER_REPO_NAME is malformed' {
        $env:COUNTER_REPO_NAME = 'bad@name'
        $initRepoCalls = 0
        Mock -CommandName 'Initialize-CounterRepository' -MockWith { $initRepoCalls++ }

        Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken 'test-token'

        $initRepoCalls | Should -Be 0
    }

    It 'returns early when GITHUB_REPOSITORY_OWNER is malformed' {
        $env:GITHUB_REPOSITORY_OWNER = 'bad-owner-'
        $env:COUNTER_REPO_OWNER = 'goodowner'  # avoid validator failing on counter owner first
        $initRepoCalls = 0
        Mock -CommandName 'Initialize-CounterRepository' -MockWith { $initRepoCalls++ }

        Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken 'test-token'

        $initRepoCalls | Should -Be 0
    }

    It 'returns early when GITHUB_REPOSITORY is malformed' {
        $env:GITHUB_REPOSITORY = 'org/bad@repo'
        $initRepoCalls = 0
        Mock -CommandName 'Initialize-CounterRepository' -MockWith { $initRepoCalls++ }

        Invoke-AllocateBuildCounter -CounterKey 'repo' -MaxRetries 5 -AppToken 'test-token'

        $initRepoCalls | Should -Be 0
    }
}
