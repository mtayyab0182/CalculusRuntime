#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────
#  Constants
# ─────────────────────────────────────────────
$ORG            = "QuantumLogicsLabs"
$BACKEND_REPO   = "CalculusRuntime-Backend"
$FRONTEND_REPO  = "CalculusRuntime-Frontend"

$UPSTREAM_BACKEND  = "https://github.com/$ORG/$BACKEND_REPO.git"
$UPSTREAM_FRONTEND = "https://github.com/$ORG/$FRONTEND_REPO.git"

# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────
function Write-Info    { param([string]$Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Cyan    }
function Write-Success { param([string]$Msg) Write-Host "[OK]    $Msg" -ForegroundColor Green   }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow  }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red     }
function Invoke-Die    { param([string]$Msg) Write-Err $Msg; exit 1                             }

function Require-Command {
    param([string]$Cmd)
    if (-not (Get-Command $Cmd -ErrorAction SilentlyContinue)) {
        Invoke-Die "'$Cmd' is not installed or not in PATH. Please install it and retry."
    }
}

function Setup-Remote {
    param(
        [string]$Dir,
        [string]$RemoteName,
        [string]$RemoteUrl
    )
    Push-Location $Dir
    try {
        $existing = git remote get-url $RemoteName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Warn "Remote '$RemoteName' already exists in '$Dir'. Updating URL."
            git remote set-url $RemoteName $RemoteUrl
        } else {
            git remote add $RemoteName $RemoteUrl
        }
        if ($LASTEXITCODE -ne 0) { Invoke-Die "Failed to set remote '$RemoteName' in '$Dir'." }
        Write-Success "Remote '$RemoteName' -> $RemoteUrl"
    } finally {
        Pop-Location
    }
}

function Pull-Branch {
    param(
        [string]$Dir,
        [string]$Remote,
        [string]$Branch = "main"
    )
    Write-Info "Pulling '$Branch' from '$Remote' in '$Dir'..."
    Push-Location $Dir
    try {
        git pull $Remote $Branch
        if ($LASTEXITCODE -ne 0) { Invoke-Die "Pull failed in '$Dir'. Resolve conflicts and retry." }
        Write-Success "Pulled '$Branch' in '$Dir'."
    } finally {
        Pop-Location
    }
}

# ─────────────────────────────────────────────
#  GitHub fork via API (auto-fork)
# ─────────────────────────────────────────────
function Invoke-AutoFork {
    param(
        [string]$Repo,
        [string]$Username,
        [string]$Token
    )
    Write-Info "Auto-forking $ORG/$Repo into your account ($Username)..."

    $headers = @{
        "Authorization" = "token $Token"
        "Accept"        = "application/vnd.github+json"
    }

    try {
        $response = Invoke-WebRequest `
            -Uri    "https://api.github.com/repos/$ORG/$Repo/forks" `
            -Method POST `
            -Headers $headers `
            -UseBasicParsing `
            -ErrorAction Stop

        switch ($response.StatusCode) {
            202 { Write-Success "Fork of '$Repo' created (or already exists). GitHub is provisioning it..." }
            default { Write-Warn "Unexpected status $($response.StatusCode) for '$Repo'." }
        }
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        switch ($code) {
            401 { Invoke-Die "Bad GitHub token — unauthorised (401)." }
            403 { Invoke-Die "GitHub API forbidden (403). Check token scopes (needs 'repo' or 'public_repo')." }
            404 { Invoke-Die "Source repo '$ORG/$Repo' not found (404). Check the org/repo names." }
            422 { Write-Warn "Fork may already exist for '$Repo' (422 Unprocessable Entity)." }
            default { Invoke-Die "Unexpected GitHub API response: HTTP $code for '$Repo'." }
        }
    }

    Write-Info "Waiting 8s for GitHub to provision the fork..."
    Start-Sleep -Seconds 8
}

# ─────────────────────────────────────────────
#  Validate & init working-tree structure
# ─────────────────────────────────────────────
function Validate-Dirs {
    foreach ($dir in @("backend", "frontend")) {
        if (-not (Test-Path $dir -PathType Container)) {
            Invoke-Die "Expected '$dir\' directory not found in $(Get-Location)."
        }

        if (-not (Test-Path "$dir\.git" -PathType Container)) {
            Write-Warn "'$dir\' is not a git repository. Initialising..."
            git -C $dir init
            if ($LASTEXITCODE -ne 0) { Invoke-Die "Failed to initialise git repo in '$dir\'." }

            # Set default branch to main
            git -C $dir checkout -b main 2>$null
            Write-Success "Initialised git repo in '$dir\'."
        }
    }
}

# ─────────────────────────────────────────────
#  Check if a fork exists on GitHub
# ─────────────────────────────────────────────
function Test-ForkExists {
    param([string]$Username, [string]$Repo)
    try {
        $resp = Invoke-WebRequest `
            -Uri             "https://github.com/$Username/$Repo" `
            -UseBasicParsing `
            -ErrorAction Stop
        return $resp.StatusCode -eq 200
    } catch {
        return $false
    }
}

# ─────────────────────────────────────────────
#  Read a non-empty value from the user
# ─────────────────────────────────────────────
function Read-NonEmpty {
    param([string]$Prompt)
    $value = ""
    while ([string]::IsNullOrWhiteSpace($value)) {
        $value = Read-Host $Prompt
        $value = $value.Trim()
        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Warn "Input cannot be empty. Please try again."
        }
    }
    return $value
}

# ─────────────────────────────────────────────
#  Read a secret (masked) non-empty value
# ─────────────────────────────────────────────
function Read-Secret {
    param([string]$Prompt)
    $value = ""
    while ([string]::IsNullOrWhiteSpace($value)) {
        $secure = Read-Host $Prompt -AsSecureString
        $value  = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                      [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
        $value  = $value.Trim()
        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Warn "Token cannot be empty. Please try again."
        }
    }
    return $value
}

# ─────────────────────────────────────────────
#  Main
# ─────────────────────────────────────────────
function Main {
    Require-Command "git"
    Validate-Dirs

    # ── Prompt for method ──────────────────────
    $method = ""
    while ($method -ne "fork" -and $method -ne "clone") {
        $method = (Read-Host "`nAre you forking or cloning the repository? (fork/clone)").Trim().ToLower()
        if ($method -ne "fork" -and $method -ne "clone") {
            Write-Warn "Invalid choice '$method'. Please enter 'fork' or 'clone'."
        }
    }

    # ══════════════════════════════════════════
    #  FORK path
    # ══════════════════════════════════════════
    if ($method -eq "fork") {

        # ── GitHub username ────────────────────
        $username = Read-NonEmpty "Enter your GitHub username"

        # ── Verify forks exist; offer auto-fork ─
        $needsFork = $false
        foreach ($repo in @($BACKEND_REPO, $FRONTEND_REPO)) {
            if (-not (Test-ForkExists -Username $username -Repo $repo)) {
                Write-Warn "Fork of '$repo' not found under github.com/$username."
                $needsFork = $true
            }
        }

        if ($needsFork) {
            $auto = (Read-Host "`nOne or more forks are missing. Auto-fork them now? (yes/no)").Trim().ToLower()
            if ($auto -eq "yes" -or $auto -eq "y") {
                $token = Read-Secret "Enter your GitHub Personal Access Token (needs 'repo' scope)"
                Invoke-AutoFork -Repo $BACKEND_REPO  -Username $username -Token $token
                Invoke-AutoFork -Repo $FRONTEND_REPO -Username $username -Token $token
            } else {
                Invoke-Die "Please fork both repositories manually at https://github.com/$ORG and re-run this script."
            }
        }

        # ── Set remotes: origin = fork, upstream = source ──
        $forkBackend  = "https://github.com/$username/$BACKEND_REPO.git"
        $forkFrontend = "https://github.com/$username/$FRONTEND_REPO.git"

        Setup-Remote -Dir "backend"  -RemoteName "origin"   -RemoteUrl $forkBackend
        Setup-Remote -Dir "backend"  -RemoteName "upstream" -RemoteUrl $UPSTREAM_BACKEND

        Setup-Remote -Dir "frontend" -RemoteName "origin"   -RemoteUrl $forkFrontend
        Setup-Remote -Dir "frontend" -RemoteName "upstream" -RemoteUrl $UPSTREAM_FRONTEND

        Pull-Branch -Dir "backend"  -Remote "origin"
        Pull-Branch -Dir "frontend" -Remote "origin"

        Write-Host ""
        Write-Success "Fork setup complete!"
        Write-Info    "  origin   -> your fork"
        Write-Info    "  upstream -> $ORG (sync future changes with 'git pull upstream main')"

    # ══════════════════════════════════════════
    #  CLONE path
    # ══════════════════════════════════════════
    } elseif ($method -eq "clone") {

        Setup-Remote -Dir "backend"  -RemoteName "origin" -RemoteUrl $UPSTREAM_BACKEND
        Setup-Remote -Dir "frontend" -RemoteName "origin" -RemoteUrl $UPSTREAM_FRONTEND

        Pull-Branch -Dir "backend"  -Remote "origin"
        Pull-Branch -Dir "frontend" -Remote "origin"

        Write-Host ""
        Write-Success "Clone setup complete!"
        Write-Info    "  origin -> $ORG (upstream source)"
    }
}

Main