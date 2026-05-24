#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  Constants
# ─────────────────────────────────────────────
ORG="QuantumLogicsLabs"
BACKEND_REPO="CalculusRuntime-Backend"
FRONTEND_REPO="CalculusRuntime-Frontend"

UPSTREAM_BACKEND="https://github.com/$ORG/$BACKEND_REPO.git"
UPSTREAM_FRONTEND="https://github.com/$ORG/$FRONTEND_REPO.git"

# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────
info()    { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
success() { echo -e "\033[1;32m[OK]\033[0m    $*"; }
warn()    { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
error()   { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }
die()     { error "$*"; exit 1; }

require() {
    command -v "$1" &>/dev/null || die "'$1' is not installed. Please install it and retry."
}

setup_remote() {
    local dir="$1" remote_name="$2" remote_url="$3"
    cd "$dir"
    if git remote get-url "$remote_name" &>/dev/null; then
        warn "Remote '$remote_name' already exists in '$dir'. Updating URL."
        git remote set-url "$remote_name" "$remote_url"
    else
        git remote add "$remote_name" "$remote_url"
    fi
    success "Remote '$remote_name' → $remote_url"
    cd - > /dev/null
}

pull_branch() {
    local dir="$1" remote="$2" branch="${3:-main}"
    info "Pulling '$branch' from '$remote' in '$dir'..."
    cd "$dir"
    git pull "$remote" "$branch" || die "Pull failed in '$dir'. Resolve conflicts and retry."
    success "Pulled '$branch' in '$dir'."
    cd - > /dev/null
}

# ─────────────────────────────────────────────
#  GitHub fork via API (auto-fork)
# ─────────────────────────────────────────────
auto_fork() {
    local repo="$1" username="$2" token="$3"
    info "Auto-forking $ORG/$repo into your account ($username)..."

    local response http_code
    response=$(curl -s -o /tmp/fork_response.json -w "%{http_code}" \
        -X POST \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/$ORG/$repo/forks")

    http_code="$response"

    case "$http_code" in
        202) success "Fork of '$repo' created (or already exists). GitHub is provisioning it..." ;;
        401) die "Bad GitHub token — unauthorised (401)." ;;
        403) die "GitHub API forbidden (403). Check token scopes (needs 'repo' or 'public_repo')." ;;
        404) die "Source repo '$ORG/$repo' not found (404). Check the org/repo names." ;;
        422) warn "Fork may already exist for '$repo' (422 Unprocessable Entity)." ;;
        *)   die "Unexpected GitHub API response: HTTP $http_code. See /tmp/fork_response.json." ;;
    esac

    # Give GitHub a moment to provision the fork
    info "Waiting 8 s for GitHub to provision the fork..."
    sleep 8
}

# ─────────────────────────────────────────────
#  Validate working-tree structure
# ─────────────────────────────────────────────
validate_dirs() {
    [[ -d "backend"  ]] || die "Expected 'backend/' directory not found in $(pwd)."
    [[ -d "frontend" ]] || die "Expected 'frontend/' directory not found in $(pwd)."
    [[ -d "backend/.git"  ]] || die "'backend/' is not a git repository."
    [[ -d "frontend/.git" ]] || die "'frontend/' is not a git repository."
}

# ─────────────────────────────────────────────
#  Main
# ─────────────────────────────────────────────
main() {
    require git
    require curl

    validate_dirs

    # ── Prompt for method ──────────────────────
    local method=""
    while [[ "$method" != "fork" && "$method" != "clone" ]]; do
        read -rp $'\nAre you forking or cloning the repository? (fork/clone): ' method
        method="${method,,}"   # lowercase
        if [[ "$method" != "fork" && "$method" != "clone" ]]; then
            warn "Invalid choice '$method'. Please enter 'fork' or 'clone'."
        fi
    done

    # ══════════════════════════════════════════
    #  FORK path
    # ══════════════════════════════════════════
    if [[ "$method" == "fork" ]]; then

        # ── GitHub username ────────────────────
        local username=""
        while [[ -z "$username" ]]; do
            read -rp "Enter your GitHub username: " username
            username="${username// /}"   # strip spaces
            [[ -z "$username" ]] && warn "Username cannot be empty."
        done

        # ── Verify forks exist; offer auto-fork ─
        local needs_fork=false
        for repo in "$BACKEND_REPO" "$FRONTEND_REPO"; do
            local check_code
            check_code=$(curl -s -o /dev/null -w "%{http_code}" \
                "https://github.com/$username/$repo")
            if [[ "$check_code" != "200" ]]; then
                warn "Fork of '$repo' not found under github.com/$username."
                needs_fork=true
            fi
        done

        if [[ "$needs_fork" == true ]]; then
            local auto=""
            read -rp $'\nOne or more forks are missing. Auto-fork them now? (yes/no): ' auto
            auto="${auto,,}"
            if [[ "$auto" == "yes" || "$auto" == "y" ]]; then
                local token=""
                while [[ -z "$token" ]]; do
                    read -rsp "Enter your GitHub Personal Access Token (needs 'repo' scope): " token
                    echo
                    [[ -z "$token" ]] && warn "Token cannot be empty."
                done
                auto_fork "$BACKEND_REPO"  "$username" "$token"
                auto_fork "$FRONTEND_REPO" "$username" "$token"
            else
                die "Please fork both repositories manually at https://github.com/$ORG and re-run this script."
            fi
        fi

        # ── Set remotes: origin = fork, upstream = source ──
        local fork_backend="https://github.com/$username/$BACKEND_REPO.git"
        local fork_frontend="https://github.com/$username/$FRONTEND_REPO.git"

        setup_remote "backend"  "origin"   "$fork_backend"
        setup_remote "backend"  "upstream" "$UPSTREAM_BACKEND"

        setup_remote "frontend" "origin"   "$fork_frontend"
        setup_remote "frontend" "upstream" "$UPSTREAM_FRONTEND"

        pull_branch "backend"  "origin"
        pull_branch "frontend" "origin"

        echo
        success "Fork setup complete!"
        info "  origin   → your fork"
        info "  upstream → $ORG (to sync future upstream changes with 'git pull upstream main')"

    # ══════════════════════════════════════════
    #  CLONE path
    # ══════════════════════════════════════════
    elif [[ "$method" == "clone" ]]; then

        setup_remote "backend"  "origin" "$UPSTREAM_BACKEND"
        setup_remote "frontend" "origin" "$UPSTREAM_FRONTEND"

        pull_branch "backend"  "origin"
        pull_branch "frontend" "origin"

        echo
        success "Clone setup complete!"
        info "  origin → $ORG (upstream source)"
    fi
}

main "$@"