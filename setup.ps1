#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────
#  Constants
# ─────────────────────────────────────────────
$ORG = "QuantumLogicsLabs"
$BACKEND_REPO = "CalculusRuntime-Backend"
$FRONTEND_REPO = "CalculusRuntime-Frontend"

$UPSTREAM_BACKEND = "https://github.com/$ORG/$BACKEND_REPO.git"
$UPSTREAM_FRONTEND = "https://github.com/$ORG/$FRONTEND_REPO.git"

# ─────────────────────────────────────────────
#  UI / Logging
# ─────────────────────────────────────────────
function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║       CalculusRuntime  —  Repo Setup         ║" -ForegroundColor DarkCyan
    Write-Host "  ║              QuantumLogicsLabs               ║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-Step {
    param([int]$Number, [int]$Total, [string]$Msg)
    Write-Host "  " -NoNewline
    Write-Host "[$Number/$Total]" -ForegroundColor DarkGray -NoNewline
    Write-Host " $Msg" -ForegroundColor White
}

function Write-Info {
    param([string]$Msg)
    Write-Host "  " -NoNewline
    Write-Host "  →  " -ForegroundColor DarkCyan -NoNewline
    Write-Host $Msg -ForegroundColor Gray
}

function Write-Success {
    param([string]$Msg)
    Write-Host "  " -NoNewline
    Write-Host "  ✔  " -ForegroundColor Green -NoNewline
    Write-Host $Msg -ForegroundColor White
}

function Write-Fail {
    param([string]$Msg)
    Write-Host ""
    Write-Host "  ✖  $Msg" -ForegroundColor Red
    Write-Host ""
}

function Invoke-Die {
    param([string]$Msg)
    Write-Fail $Msg
    exit 1
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "  ── $Title " -ForegroundColor DarkCyan -NoNewline
    Write-Host ("─" * (44 - $Title.Length)) -ForegroundColor DarkGray
}

function Write-Summary {
    param([string]$Mode, [string]$Username = "")
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║               Setup Complete!                ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    if ($Mode -eq "fork") {
        Write-Host "  Remotes configured:" -ForegroundColor DarkGray
        Write-Host "    origin   " -ForegroundColor Cyan -NoNewline
        Write-Host "→ github.com/$Username/{repo}  (your fork)" -ForegroundColor White
        Write-Host "    upstream " -ForegroundColor Cyan -NoNewline
        Write-Host "→ github.com/$ORG/{repo}  (source)" -ForegroundColor White
        Write-Host ""
        Write-Host "  Sync upstream anytime:" -ForegroundColor DarkGray
        Write-Host "    git pull upstream main" -ForegroundColor Yellow
    }
    else {
        Write-Host "  Remotes configured:" -ForegroundColor DarkGray
        Write-Host "    origin " -ForegroundColor Cyan -NoNewline
        Write-Host "→ github.com/$ORG/{repo}  (source)" -ForegroundColor White
    }
    Write-Host ""
}

# ─────────────────────────────────────────────
#  Spinner
# ─────────────────────────────────────────────
function Invoke-WithSpinner {
    param([string]$Label, [scriptblock]$Action)
    $frames = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
    $job = Start-Job -ScriptBlock $Action
    $i = 0
    while ($job.State -eq "Running") {
        Write-Host "`r  " -NoNewline
        Write-Host $frames[$i % $frames.Length] -ForegroundColor Cyan -NoNewline
        Write-Host "  $Label" -NoNewline -ForegroundColor Gray
        Start-Sleep -Milliseconds 80
        $i++
    }
    $result = Receive-Job $job -Wait -AutoRemoveJob 2>&1
    Write-Host "`r  ✔  $Label          " -ForegroundColor Green
    return $result
}

# ─────────────────────────────────────────────
#  Prerequisite check
# ─────────────────────────────────────────────
function Require-Command {
    param([string]$Cmd)
    if (-not (Get-Command $Cmd -ErrorAction SilentlyContinue)) {
        Invoke-Die "'$Cmd' is not installed or not in PATH. Install it from https://git-scm.com and retry."
    }
}

# ─────────────────────────────────────────────
#  Git helpers
# ─────────────────────────────────────────────
function Setup-Remote {
    param([string]$Dir, [string]$RemoteName, [string]$RemoteUrl)
    Push-Location $Dir
    try {
        git remote get-url $RemoteName 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            git remote set-url $RemoteName $RemoteUrl 2>&1 | Out-Null
        }
        else {
            git remote add $RemoteName $RemoteUrl 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -ne 0) { Invoke-Die "Failed to configure remote '$RemoteName' in '$Dir'." }
        Write-Success "$Dir  [$RemoteName]  $RemoteUrl"
    }
    finally {
        Pop-Location
    }
}

function Pull-Branch {
    param([string]$Dir, [string]$Remote, [string]$Branch = "main")
    Push-Location $Dir
    try {
        $output = git pull $Remote $Branch 2>&1
        if ($LASTEXITCODE -ne 0) { Invoke-Die "Pull failed in '$Dir':`n$output`nResolve conflicts and retry." }
        Write-Success "Pulled '$Branch' in $Dir"
    }
    finally {
        Pop-Location
    }
}

# ─────────────────────────────────────────────
#  Directory & git init
# ─────────────────────────────────────────────
function Validate-And-Init-Dirs {
    foreach ($dir in @("backend", "frontend")) {
        if (-not (Test-Path $dir -PathType Container)) {
            Invoke-Die "Directory '$dir\' not found in $(Get-Location). Run this script from the project root."
        }
        if (-not (Test-Path "$dir\.git" -PathType Container)) {
            Write-Info "Initialising git repository in '$dir\'..."
            git -C $dir init 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { Invoke-Die "Failed to initialise git repo in '$dir\'." }
            git -C $dir checkout -b main 2>$null | Out-Null
            Write-Success "Git initialised in '$dir\'"
        }
    }
}

# ─────────────────────────────────────────────
#  GitHub API — fork existence check
# ─────────────────────────────────────────────
function Test-ForkExists {
    param([string]$Username, [string]$Repo)
    try {
        $r = Invoke-WebRequest -Uri "https://github.com/$Username/$Repo" -UseBasicParsing -ErrorAction Stop
        return $r.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

# ─────────────────────────────────────────────
#  GitHub API — auto-fork
# ─────────────────────────────────────────────
function Invoke-AutoFork {
    param([string]$Repo, [string]$Username, [string]$Token)
    Write-Info "Forking $ORG/$Repo → $Username/$Repo ..."
    $headers = @{
        "Authorization" = "token $Token"
        "Accept"        = "application/vnd.github+json"
    }
    try {
        $response = Invoke-WebRequest `
            -Uri             "https://api.github.com/repos/$ORG/$Repo/forks" `
            -Method          POST `
            -Headers         $headers `
            -UseBasicParsing `
            -ErrorAction     Stop

        if ($response.StatusCode -eq 202) {
            Write-Success "Fork of '$Repo' queued on GitHub"
        }
    }
    catch {
        $code = $_.Exception.Response.StatusCode.value__
        switch ($code) {
            401 { Invoke-Die "GitHub token rejected (401). Ensure the token is valid." }
            403 { Invoke-Die "GitHub API forbidden (403). Token needs 'repo' or 'public_repo' scope." }
            404 { Invoke-Die "Repository '$ORG/$Repo' not found (404). Verify the org and repo names." }
            422 { Write-Info "Fork of '$Repo' already exists — skipping creation." }
            default { Invoke-Die "GitHub API returned HTTP $code for '$Repo'. Check your network and token." }
        }
    }
}

# ─────────────────────────────────────────────
#  Input helpers
# ─────────────────────────────────────────────
function Read-NonEmpty {
    param([string]$Prompt)
    do {
        $value = (Read-Host "  $Prompt").Trim()
        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Fail "Input cannot be empty. Please try again."
        }
    } while ([string]::IsNullOrWhiteSpace($value))
    return $value
}

function Read-Secret {
    param([string]$Prompt)
    do {
        $secure = Read-Host "  $Prompt" -AsSecureString
        $value = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
        $value = $value.Trim()
        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Fail "Token cannot be empty. Please try again."
        }
    } while ([string]::IsNullOrWhiteSpace($value))
    return $value
}

function Read-Choice {
    param([string]$Prompt, [string[]]$Valid)
    do {
        $value = (Read-Host "  $Prompt").Trim().ToLower()
        if ($value -notin $Valid) {
            Write-Fail "Invalid input '$value'. Please enter one of: $($Valid -join ' / ')."
        }
    } while ($value -notin $Valid)
    return $value
}

# ─────────────────────────────────────────────
#  Main
# ─────────────────────────────────────────────
function Main {
    Write-Banner

    # ── Prerequisites ──────────────────────────
    Write-SectionHeader "Checking Prerequisites"
    Require-Command "git"
    Write-Success "git found  ($(git --version))"

    # ── Directory validation ───────────────────
    Write-SectionHeader "Validating Project Structure"
    Validate-And-Init-Dirs

    # ── Method selection ───────────────────────
    Write-SectionHeader "Setup Mode"
    Write-Host "  Are you forking or cloning?" -ForegroundColor White
    Write-Host "    fork   — personal copy under your GitHub account" -ForegroundColor DarkGray
    Write-Host "    clone  — direct read from $ORG" -ForegroundColor DarkGray
    Write-Host ""
    $method = Read-Choice -Prompt "Enter choice (fork/clone)" -Valid @("fork", "clone")

    # ══════════════════════════════════════════
    #  FORK path
    # ══════════════════════════════════════════
    if ($method -eq "fork") {

        Write-SectionHeader "GitHub Account"
        $username = Read-NonEmpty -Prompt "GitHub username"

        # ── Check fork existence ───────────────
        Write-SectionHeader "Verifying Forks"
        $missing = @()
        foreach ($repo in @($BACKEND_REPO, $FRONTEND_REPO)) {
            Write-Info "Checking github.com/$username/$repo ..."
            if (-not (Test-ForkExists -Username $username -Repo $repo)) {
                Write-Info "Not found — will be forked automatically"
                $missing += $repo
            }
            else {
                Write-Success "github.com/$username/$repo exists"
            }
        }

        # ── Auto-fork missing repos ────────────
        if ($missing.Count -gt 0) {
            Write-SectionHeader "Auto-Forking"
            $token = Read-Secret -Prompt "GitHub Personal Access Token (needs 'repo' scope)"
            Write-Host ""
            foreach ($repo in $missing) {
                Invoke-AutoFork -Repo $repo -Username $username -Token $token
            }
            Write-Host ""
            Write-Info "Waiting 10s for GitHub to provision the fork(s)..."
            Start-Sleep -Seconds 10
        }

        # ── Configure remotes ──────────────────
        Write-SectionHeader "Configuring Remotes"
        Setup-Remote -Dir "backend"  -RemoteName "origin"   -RemoteUrl "https://github.com/$username/$BACKEND_REPO.git"
        Setup-Remote -Dir "backend"  -RemoteName "upstream" -RemoteUrl $UPSTREAM_BACKEND
        Setup-Remote -Dir "frontend" -RemoteName "origin"   -RemoteUrl "https://github.com/$username/$FRONTEND_REPO.git"
        Setup-Remote -Dir "frontend" -RemoteName "upstream" -RemoteUrl $UPSTREAM_FRONTEND

        # ── Pull ───────────────────────────────
        Write-SectionHeader "Pulling Latest Code"
        Pull-Branch -Dir "backend"  -Remote "origin"
        Pull-Branch -Dir "frontend" -Remote "origin"

        Write-Summary -Mode "fork" -Username $username

        # ══════════════════════════════════════════
        #  CLONE path
        # ══════════════════════════════════════════
    }
    elseif ($method -eq "clone") {

        Write-SectionHeader "Configuring Remotes"
        Setup-Remote -Dir "backend"  -RemoteName "origin" -RemoteUrl $UPSTREAM_BACKEND
        Setup-Remote -Dir "frontend" -RemoteName "origin" -RemoteUrl $UPSTREAM_FRONTEND

        Write-SectionHeader "Pulling Latest Code"
        Pull-Branch -Dir "backend"  -Remote "origin"
        Pull-Branch -Dir "frontend" -Remote "origin"

        Write-Summary -Mode "clone"
    }
}

Main