# Contributing to CalculusRuntime

Thank you for your interest in contributing to **CalculusRuntime** — a multi-repository monorepo by [QuantumLogicsLabs](https://github.com/QuantumLogicsLabs) that brings together a symbolic calculus engine (SLaNg), an AI-powered calculus solver, a React/SvelteKit frontend, and a Python ML backend into one cohesive platform.

This document covers everything you need to know to contribute effectively, from setting up your environment to getting your pull request merged.

---

## Table of Contents

- [Project Architecture](#project-architecture)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Fork & Clone](#fork--clone)
  - [Setup Scripts](#setup-scripts)
- [Development Workflow](#development-workflow)
  - [Branching Strategy](#branching-strategy)
  - [Commit Conventions](#commit-conventions)
  - [Pull Request Process](#pull-request-process)
- [Submodule Contributions](#submodule-contributions)
  - [SLaNg (Symbolic Language for Numerics)](#slang-symbolic-language-for-numerics)
  - [CalculusSolver (Python ML Core)](#calculussolver-python-ml-core)
  - [Frontend (React)](#frontend-react)
  - [Backend](#backend)
- [Coding Standards](#coding-standards)
  - [JavaScript / TypeScript](#javascript--typescript)
  - [Python](#python)
  - [Svelte](#svelte)
- [Testing](#testing)
  - [Running Tests](#running-tests)
  - [Writing Tests](#writing-tests)
- [Documentation](#documentation)
- [Issue Reporting](#issue-reporting)
- [Feature Requests](#feature-requests)
- [Security Vulnerabilities](#security-vulnerabilities)
- [License](#license)

---

## Project Architecture

CalculusRuntime is organized as a **monorepo with nested git submodules**. The three primary layers are:

| Layer | Technology | Purpose |
|---|---|---|
| **SLaNg** | JavaScript (Node.js / npm) | Symbolic math engine — parses, evaluates, differentiates, integrates expressions |
| **CalculusSolver** | Python (ML) | Trains and runs an inference model that interprets natural-language calculus problems |
| **Frontend** | React + Vite / SvelteKit | Interactive web UI for users to interact with both systems |
| **Backend** | Python | API layer bridging the frontend with the ML inference engine |

Understanding these layers before contributing to any single one will save you time and prevent regressions.

---

## Repository Structure

```
CalculusRuntime/
├── calculussolver/          # Python ML pipeline (training, inference, eval)
│   ├── data_pipeline/       # Data generation and processing (JS + Python)
│   ├── inference/           # Inference engine
│   ├── training/            # Model training scripts
│   ├── eval/                # Model evaluation
│   ├── tokenizer/           # Vocabulary generation
│   ├── slang/               # SLaNg submodule
│   │   ├── src/             # Core SLaNg source (basic, advanced, complex)
│   │   ├── docs/            # Per-function API docs
│   │   ├── experiments/     # Exploratory scripts
│   │   └── website/         # SvelteKit demo site
│   └── website/             # React UI for CalculusSolver
├── frontend/                # Main React frontend
│   ├── src/
│   │   ├── components/      # Shared UI components
│   │   ├── pages/           # Route-level pages
│   │   └── utils/
└── backend/                 # API server
```

---

## Getting Started

### Prerequisites

Make sure you have the following installed:

- **Git** ≥ 2.30
- **Node.js** ≥ 18.x and **npm** ≥ 9.x
- **Python** ≥ 3.10 and **pip**
- A GitHub account

### Fork & Clone

The project uses submodules. Use the automated setup scripts provided rather than a bare `git clone`.

1. Fork the top-level `CalculusRuntime` repository to your GitHub account.
2. Clone your fork:

```bash
git clone https://github.com/<your-username>/CalculusRuntime.git
cd CalculusRuntime
```

3. Run the setup script (see below) to initialise and configure all submodule remotes.

### Setup Scripts

Two setup scripts are provided to handle the multi-submodule remote configuration automatically.

**Linux / macOS:**
```bash
chmod +x setup.sh
./setup.sh
```

**Windows (PowerShell):**
```powershell
.\setup.ps1
```

When prompted, choose **fork** if you want personal copies of each submodule under your GitHub account (recommended for contributors), or **clone** for read-only direct access. For fork mode you will need a GitHub Personal Access Token with `repo` scope.

After setup, each submodule will have:
- `origin` → your fork
- `upstream` → the QuantumLogicsLabs canonical repo

To sync with upstream at any time:
```bash
git -C <submodule-path> pull upstream main
```

---

## Development Workflow

### Branching Strategy

We use a **feature-branch workflow**. All work happens on branches; `main` is always deployable.

| Branch type | Naming pattern | Example |
|---|---|---|
| Feature | `feat/<short-description>` | `feat/taylor-series-ui` |
| Bug fix | `fix/<short-description>` | `fix/integration-overflow` |
| Documentation | `docs/<short-description>` | `docs/slang-api-helpers` |
| Refactor | `refactor/<short-description>` | `refactor/inference-engine` |
| Test | `test/<short-description>` | `test/converter-edge-cases` |

Always branch off `main`:
```bash
git checkout main
git pull upstream main
git checkout -b feat/your-feature-name
```

### Commit Conventions

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification. Every commit message must have the form:

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`

**Scopes** (match the submodule/layer): `slang`, `solver`, `frontend`, `backend`, `pipeline`, `tokenizer`, `eval`, `ci`

**Examples:**
```
feat(slang): add lagrange multipliers solver
fix(solver): handle division by zero in inference engine
docs(slang): add chainRuleDifferentiate explanation
test(frontend): add unit tests for VolumeCalculator page
chore(ci): update npm publish workflow
```

Keep the subject line under 72 characters. Use the body to explain *why*, not *what*.

### Pull Request Process

1. Push your branch to your fork: `git push origin feat/your-feature-name`
2. Open a Pull Request against `QuantumLogicsLabs/CalculusRuntime:main`.
3. Fill in the PR template completely — include a description, motivation, and screenshots for UI changes.
4. Ensure all CI checks pass (tests, lint).
5. Request a review from at least one maintainer.
6. Address all review comments. Push additional commits to the same branch — do not force-push after a review has started.
7. A maintainer will squash-merge once the PR is approved.

**Do not** merge your own PRs unless you are a maintainer and the PR has been approved by another team member.

---

## Submodule Contributions

Each submodule has its own `setup.sh`/`setup.ps1`. Run the script for whichever submodule you are working on before making changes.

### SLaNg (Symbolic Language for Numerics)

Located at `calculussolver/slang/`. Published as an npm package.

**Install dependencies:**
```bash
cd calculussolver/slang
npm install
```

**Source layout:**
- `src/core/basic.js` — fundamental term/fraction/equation operations
- `src/core/advanced.js` — chain rule, integration by parts, Taylor series, etc.
- `src/core/complex.js` — multi-variable, gradient, Lagrange multipliers
- `src/math/` — linear algebra, ODEs, statistics helpers
- `src/utils/` — caching, error handling, preprocessing
- `src/convertor.js` — LaTeX ↔ SLaNg conversion

**Documentation:** Every public function must have a corresponding `.md` file under `docs/explaination/`. Match the existing format in `docs/explaination/SLaNg-Basic/` or `docs/explaination/SLaNg-Advanced/`.

**Experiments:** Use the `experiments/` directory for exploratory or demo scripts. Do not merge experimental scripts into `src/`.

### CalculusSolver (Python ML Core)

Located at `calculussolver/`.

**Create and activate the virtual environment:**
```bash
cd calculussolver
python -m venv .venv
# Linux/macOS
source .venv/bin/activate
# Windows
.venv\Scripts\activate
pip install -r requirements.txt
```

**Key modules:**
- `data_pipeline/` — generates and splits training data (mix of Python and JS)
- `training/model_trainer.py` — model training
- `eval/evaluate_model.py` — evaluation harness
- `inference/inference_engine.py` — production inference
- `tokenizer/` — vocabulary generation

When adding new training data patterns, update `data_pipeline/data_generator.py` and regenerate `data/dataset.json` using the pipeline scripts. Do not commit generated artifacts (`.pkl` model files) unless explicitly requested by a maintainer.

### Frontend (React)

Located at `frontend/` and `calculussolver/website/`.

```bash
cd frontend
npm install
npm run dev
```

Pages live in `src/pages/`. Shared components go in `src/components/`. Do not put page-specific logic in shared components.

For the SvelteKit demo site (`calculussolver/slang/website/`):
```bash
cd calculussolver/slang/website
npm install
npm run dev
```

### Backend

Located at `backend/`. Refer to `backend/LICENSE` and any local README for setup instructions specific to the API server.

---

## Coding Standards

### JavaScript / TypeScript

- **Style:** follow the existing style in each file (the codebase uses ES modules).
- No unused variables or imports.
- Prefer `const` over `let`; avoid `var`.
- Use descriptive names — this is a math library; clarity matters more than brevity.
- All new utility functions must include JSDoc comments.

### Python

- Follow [PEP 8](https://peps.python.org/pep-0008/).
- Type annotations are encouraged for all public functions.
- Use docstrings (Google style) for every public class and function.
- Do not commit `.pyc` files or `__pycache__/` directories — these are gitignored.
- Always install dependencies inside the virtual environment. Use `--break-system-packages` only if `pip` explicitly requires it.

### Svelte

- Follow the existing component conventions in `calculussolver/slang/website/src/`.
- Keep components small and single-purpose.
- Use SvelteKit's file-based routing; do not work around it.

---

## Testing

### Running Tests

**SLaNg (JavaScript):**
```bash
cd calculussolver/slang
npm test
```

Unit tests live in `tests/unit/`. Integration tests live in `tests/integration/`.

**CalculusSolver (Python):**
```bash
cd calculussolver
python -m pytest
```

**Frontend:**
```bash
cd frontend
npm test
```

### Writing Tests

- Every new public function in SLaNg must have at least one unit test in `tests/unit/`.
- Tests for the Python inference engine and data pipeline should be placed alongside the module they cover (e.g., `inference/test_inference_engine.py`).
- Use descriptive test names: `test_chainRule_differentiates_composite_function`, not `test1`.
- Aim for edge cases: zero coefficients, division by zero, empty inputs, single-term expressions, and symbolic vs. numeric inputs.
- Do not commit tests that `console.log` or `print` to stdout without a clear reason — use assertions.

---

## Documentation

Good documentation is a first-class contribution in this project.

- API docs for SLaNg functions live in `calculussolver/slang/docs/explaination/`. Each `.md` file should include: function signature, description, parameters, return value, and at least one example.
- High-level architecture notes go in `calculussolver/docs/ARCHITECTURE.md` or `calculussolver/slang/docs/ARCHITECTURE.MD`.
- User-facing guides go in `calculussolver/docs/GUIDE.md`.
- If you add a new page or major component to the frontend, add a brief description to the relevant guide.

Typo fixes and clarity improvements to existing docs are always welcome — open a PR with type `docs`.

---

## Issue Reporting

Before opening an issue, please search existing issues to avoid duplicates.

When filing a bug report, include:

1. **Environment** — OS, Node.js version, Python version, browser (if UI-related)
2. **Reproduction steps** — the minimal sequence of actions or code that reproduces the problem
3. **Expected behaviour** — what you expected to happen
4. **Actual behaviour** — what actually happened, including any error messages or stack traces
5. **Module affected** — SLaNg, CalculusSolver, Frontend, Backend, or setup scripts

Label your issue appropriately: `bug`, `docs`, `question`, `help wanted`, etc.

---

## Feature Requests

Open a GitHub Issue with the label `enhancement`. Describe:

- The problem you are trying to solve
- Your proposed solution
- Any alternatives you considered
- Which submodule(s) would be affected

Large features (new calculus operations, new ML model architectures, new frontend pages) should be discussed in an issue before a PR is opened, to avoid wasted effort.

---

## Security Vulnerabilities

**Do not open a public issue for security vulnerabilities.**

Please report security issues privately by emailing the maintainers directly (see the repository's security policy or contact information). Include a description of the vulnerability, steps to reproduce, and potential impact. We aim to acknowledge security reports within 48 hours.

---

## License

By contributing to CalculusRuntime, you agree that your contributions will be licensed under the same license as the submodule you are contributing to. Each submodule contains its own `LICENSE` file. Please review it before submitting your first pull request.

---

*Thank you for helping make CalculusRuntime better. Every contribution — code, docs, tests, or bug reports — is valued.*
