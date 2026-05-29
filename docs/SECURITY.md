# Security Policy

## Supported Versions

The table below shows which versions of CalculusRuntime and its submodules currently receive security updates.

| Component | Supported Versions |
|---|---|
| CalculusRuntime (root) | `main` branch only |
| SLaNg (npm package) | Latest published version on npm |
| CalculusSolver (Python ML core) | `main` branch only |
| Frontend (React) | `main` branch only |
| Backend (API) | `main` branch only |

Older pinned versions and feature branches do not receive backported security fixes. If you are running a fork or a pinned version, we strongly recommend keeping up with `upstream/main`.

---

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub Issues, Pull Requests, or Discussions.** Public disclosure before a fix is available puts all users of the project at risk.

### How to Report

Send a detailed report by email to the QuantumLogicsLabs security contact listed in the repository's GitHub Security Advisories tab (under **Security → Advisories → Report a vulnerability**). If that tab is unavailable, email the maintainers directly via the address on the organisation's GitHub profile.

### What to Include

A good report helps us triage and fix the issue faster. Please include as much of the following as possible:

- **Component affected** — which submodule(s): SLaNg, CalculusSolver, Frontend, Backend, or the setup scripts
- **Description** — a clear explanation of the vulnerability and what an attacker could achieve
- **Reproduction steps** — the minimal sequence of inputs, API calls, or actions that triggers the issue
- **Environment** — OS, Node.js version, Python version, browser (if applicable), and any relevant dependency versions
- **Proof of concept** — code snippets, payloads, or screenshots that demonstrate the issue (do not publish these publicly)
- **Severity estimate** — your assessment of the impact: informational, low, medium, high, or critical
- **Suggested fix** — if you have one, we welcome it

### What Happens Next

| Timeframe | Action |
|---|---|
| Within **48 hours** | We acknowledge receipt of your report |
| Within **7 days** | We confirm whether the issue is valid and provide an initial severity assessment |
| Within **30 days** | We aim to have a fix developed, reviewed, and ready for release |
| At release | We publish a GitHub Security Advisory crediting you (unless you prefer to remain anonymous) |

If the issue requires more time — for example, because it affects a third-party dependency — we will keep you informed of progress and agree on an extended disclosure deadline before anything is made public.

---

## Disclosure Policy

We follow a **coordinated disclosure** model:

1. The reporter notifies us privately.
2. We work with the reporter to understand and fix the issue.
3. A fix is released and a GitHub Security Advisory is published.
4. The reporter may then publish their own write-up if they choose.

We ask reporters to keep the details of the vulnerability private until we have released a fix and published the advisory. In return, we commit to acting promptly, keeping you informed, and publicly crediting your discovery.

---

## Scope

### In Scope

The following are considered in scope for security reports:

- **SLaNg symbolic engine** — unsafe evaluation of mathematical expressions, prototype pollution, ReDoS in the parser or converter, or unintended code execution triggered by crafted input
- **CalculusSolver inference engine** — model input injection, arbitrary code execution via the data pipeline or tokeniser, or unsafe deserialisation of `.pkl` model files
- **Backend API** — authentication bypass, injection attacks, path traversal, insecure direct object references, or unintended data exposure
- **Frontend (React / SvelteKit)** — cross-site scripting (XSS), cross-site request forgery (CSRF), or content injection through the math rendering layer
- **Setup scripts** (`setup.sh`, `setup.ps1`) — command injection, unsafe handling of user-supplied tokens, or privilege escalation

### Out of Scope

The following are **not** in scope:

- Vulnerabilities in third-party dependencies (please report those directly to the upstream maintainers; we will update our dependency once they publish a fix)
- Issues that require physical access to a machine running the project
- Denial-of-service attacks that require sending extremely large volumes of requests
- Social engineering attacks targeting project maintainers
- Findings from automated scanners submitted without a written explanation of exploitability
- Missing security headers on the demo/development site
- Issues in the `.venv` pip internals (report those to the pip project)

---

## Security Best Practices for Contributors

If you are contributing code, please keep the following in mind:

- **Never commit secrets.** API keys, GitHub tokens, and credentials must never appear in source files, commit history, or log output. Use environment variables and add secret files to `.gitignore`.
- **Validate all inputs.** Any data received from user input, API calls, or external files — especially mathematical expressions passed to the SLaNg engine — should be validated and sanitised before processing.
- **Avoid `eval` and `Function()`.** Dynamic code execution from user-supplied strings is prohibited unless the input has been fully validated and sandboxed.
- **Handle `.pkl` files carefully.** Python pickle deserialisation can execute arbitrary code. Only load model files from trusted, verified sources. Do not expose model loading to user-controlled file paths.
- **Pin dependencies.** When adding a new npm or pip dependency, pin to a specific version in `package.json` / `requirements.txt` and document why it is needed.
- **Use the virtual environment.** Always install Python dependencies inside `.venv` to isolate them from the system Python.

---

## Known Limitations

- The SLaNg engine evaluates symbolic expressions structurally rather than via `eval`, but contributors should remain vigilant when adding new parsing paths.
- Model files (`.pkl`) are committed for convenience during development. In a production deployment, these should be fetched from a verified, access-controlled artifact store.

---

## Attribution

We are grateful to all researchers and contributors who responsibly disclose security issues. With your permission, your name and a summary of your finding will be included in the GitHub Security Advisory when the fix is released.

---

*Security is everyone's responsibility. If something looks wrong, please tell us.*
