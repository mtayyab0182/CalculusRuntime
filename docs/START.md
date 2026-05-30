# Starting CalcVoyager Locally

Three services run in parallel. Open three terminal windows and start each one.

---

## Prerequisites

| Tool    | Min version | Check              |
| ------- | ----------- | ------------------ |
| Node.js | 18+         | `node -v`          |
| npm     | 9+          | `npm -v`           |
| Python  | 3.10+       | `python --version` |
| pip     | 23+         | `pip --version`    |

---

## 1 — Backend (FastAPI + SQLite)

```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS / Linux
source .venv/bin/activate

pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

The API will be available at `http://localhost:8000`.  
Interactive docs: `http://localhost:8000/docs`

### Environment variables (optional)

Create `backend/.env` to override defaults:

```env
SECRET_KEY=replace-with-a-long-random-string
TOKEN_EXPIRE_MINUTES=10080
DB_PATH=calcvoyager.db
ALLOWED_ORIGINS=http://localhost:3000
```

The SQLite database file (`calcvoyager.db`) is created automatically on first run — no setup needed.

---

## 2 — Frontend (React)

```bash
cd frontend
npm install
npm start
```

Opens at `http://localhost:3000`.

The frontend talks to the backend at `http://localhost:8000` by default.  
To change the API URL, set it in `frontend/.env`:

```env
REACT_APP_API_URL=http://localhost:8000
```

---

## 3 — CalculusSolver ML API (optional)

Only needed if you want to run the neural solver locally instead of using the hosted Streamlit app.

```bash
cd calculussolver
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS / Linux
source .venv/bin/activate

pip install -r requirements.txt
uvicorn api.app:app --reload --port 8001
```

The solver API will be at `http://localhost:8001`.

> **Note:** The solver requires a trained model checkpoint in `calculussolver/checkpoints/`. Without one it starts in fallback mode (polynomial-only solver). The hosted version at `https://dapeaqzot5jtellyuyxjrf.streamlit.app/` is used by default in the frontend.

### Run the Streamlit UI instead

```bash
cd calculussolver
streamlit run streamlit_app.py
```

Opens at `http://localhost:8501`.

---

## All three together (quick reference)

```
Terminal 1 — Backend
  cd backend && .venv\Scripts\activate && uvicorn main:app --reload --port 8000

Terminal 2 — Frontend
  cd frontend && npm start

Terminal 3 — Solver (optional)
  cd calculussolver && .venv\Scripts\activate && uvicorn api.app:app --reload --port 8001
```

---

## Port summary

| Service                            | URL                                           |
| ---------------------------------- | --------------------------------------------- |
| Frontend                           | http://localhost:3000                         |
| Backend API                        | http://localhost:8000                         |
| Backend docs (Swagger)             | http://localhost:8000/docs                    |
| Solver API (local, optional)       | http://localhost:8001                         |
| Solver Streamlit (local, optional) | http://localhost:8501                         |
| Solver Streamlit (hosted)          | https://dapeaqzot5jtellyuyxjrf.streamlit.app/ |

---

## First-time walkthrough

1. Start the backend (Terminal 1).
2. Start the frontend (Terminal 2).
3. Open `http://localhost:3000`.
4. Click **Sign up** — create an account.
5. Study a guide, complete a section, take a quiz, bookmark a page.
6. Open **Dashboard** to see your progress synced to the backend.
7. Click **AI Solver** to use the hosted CalculusSolver model.

---

## Troubleshooting

**`ModuleNotFoundError` in backend**  
Make sure the virtual environment is activated before running uvicorn.

**CORS errors in browser**  
Confirm the backend is running on port 8000 and `ALLOWED_ORIGINS` includes `http://localhost:3000`.

**`npm install` fails**  
Delete `frontend/node_modules` and `frontend/package-lock.json`, then run `npm install` again.

**Database locked error**  
Only one uvicorn worker should run locally. The default `--reload` flag is fine; avoid `--workers 2+` with SQLite.

**Solver returns 503**  
No checkpoint found. Either train the model (see `calculussolver/docs/GUIDE.md`) or use the hosted Streamlit app — the frontend uses it by default.
