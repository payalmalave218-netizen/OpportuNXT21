# OpportuNXT — Student Opportunity Discovery Platform

**Discover. Apply. Grow.**

One platform for every opportunity that can shape your future.

Built for **FIT-FEST Hackathon 2026**.

---

## 1. Problem Statement

Students routinely miss valuable opportunities — internships, hackathons, scholarships, certifications, competitions, workshops, and courses — because relevant information is scattered across dozens of websites, social media pages, college WhatsApp/Telegram groups, and newsletters. There is no single place a student can go to see everything relevant to *their* profile.

## 2. Solution

OpportuNXT aggregates opportunities into a single searchable, filterable platform, and layers a transparent, rule-based recommendation engine on top so each student sees a personalized, explainable match score for every opportunity based on their skills, interests, education, and category preferences.

## 3. Features

- Student registration & login (email/password, demo account included)
- Rich student profile (education, branch, year, skills, interests, preferred categories, location, work mode)
- Personalized dashboard: stats, "Closing Soon" alerts, recommended opportunities, category analytics
- Explore page with search + filters (category, mode, location, skill, deadline) and sorting
- Opportunity detail pages with full eligibility, benefits, application process, and external apply link
- Transparent match-percentage recommendation engine with a "Why this matches you" explanation
- Save/bookmark opportunities, persisted per user
- Activity logging (views, applies, saves) that feeds a small analytics dashboard (Recharts)
- Automatic "Expired" state for opportunities past their deadline
- Fully responsive, accessible UI (desktop, laptop, tablet, mobile)
- Seeded with 22 realistic demo opportunities across all 7 categories

## 4. Technology Stack

| Layer          | Technology                                  |
|----------------|----------------------------------------------|
| Frontend       | React 18 + Vite, React Router                |
| Styling        | Tailwind CSS                                 |
| Icons          | lucide-react                                 |
| Charts         | Recharts                                     |
| Backend        | Python, FastAPI                              |
| Database       | SQLite (via SQLAlchemy ORM)                  |
| Auth           | Email/password, PBKDF2-SHA256 hashing, signed session tokens (stdlib only) |
| Deployment     | Docker (multi-stage), Google Cloud Run       |

No paid or external AI APIs are used anywhere in the application.

## 5. Architecture

```
┌─────────────────────────┐        HTTPS         ┌──────────────────────────┐
│   React (Vite) SPA      │ ───────────────────▶ │   FastAPI backend        │
│   served as static      │ ◀─────────────────── │   (SQLAlchemy + SQLite)  │
│   files by FastAPI      │        JSON           │   /register /login       │
│   in production          │                       │   /opportunities ...     │
└─────────────────────────┘                       └──────────────────────────┘
```

In production, the frontend is built into static files and served directly by the
FastAPI app (single container, single Cloud Run service, one public URL). In local
development, the Vite dev server and the FastAPI dev server run separately on
different ports.

### Project structure

```
opportunxt/
├── backend/
│   ├── app/
│   │   ├── main.py            # FastAPI app & all API routes
│   │   ├── models.py          # SQLAlchemy models (User, Opportunity, SavedOpportunity, Activity)
│   │   ├── schemas.py         # Pydantic request/response schemas
│   │   ├── auth.py            # password hashing + signed session tokens
│   │   ├── recommendations.py # transparent match-score algorithm
│   │   ├── seed_data.py       # 22 demo opportunities + demo user
│   │   └── database.py        # SQLAlchemy engine/session setup
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── pages/              # Landing, Login, Register, Dashboard, Profile, Explore, OpportunityDetails, Saved
│   │   ├── components/         # Navbar, Footer, OpportunityCard
│   │   ├── context/            # AuthContext, ToastContext
│   │   ├── api.js               # API client
│   │   └── constants.js         # categories, filters, skills
│   ├── index.html
│   └── package.json
├── Dockerfile                  # multi-stage build: Node build → Python runtime
├── docker-compose.yml
├── .env.example
└── README.md
```

## 6. How the Recommendation System Works

The match score is a fully transparent, deterministic weighted formula — **no external AI API is used**:

| Factor                  | Weight |
|--------------------------|--------|
| Skills match             | 40%    |
| Interest match           | 30%    |
| Category preference      | 20%    |
| Education/branch match   | 10%    |

For each opportunity, the backend compares the student's profile fields against the
opportunity's skills, category, and eligibility text, and produces:

- A **match percentage** (0–100)
- A list of **plain-language reasons** ("Matches your skill(s): Python", "You prefer Hackathon opportunities", etc.), shown as "Why this matches you" on the opportunity detail page.

See `backend/app/recommendations.py` for the full implementation.

## 7. Screenshots

> Add screenshots of the Landing page, Dashboard, Explore page, and Opportunity Details
> page here after running the app locally, e.g.:
>
> `![Dashboard](docs/screenshots/dashboard.png)`

## 8. Local Setup

### Prerequisites

- Python 3.11+
- Node.js 20+
- npm

### Backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp ../.env.example ../.env       # optional, defaults work out of the box
uvicorn app.main:app --reload --port 8000
```

The API will be available at `http://localhost:8000` and seeds itself automatically
on first startup (22 demo opportunities + a demo account).

### Frontend

```bash
cd frontend
npm install
npm run dev
```

The app will be available at `http://localhost:5173` and talks to the backend at
`http://localhost:8000` by default (see `VITE_API_URL` in `.env.example` to override).

### Demo account

```
Email:    demo@opportunxt.com
Password: demo123
```

## 9. Environment Variables

See `.env.example` for the full list. Key variables:

| Variable        | Description                                         | Default                        |
|------------------|------------------------------------------------------|---------------------------------|
| `SECRET_KEY`     | Secret used to sign session tokens                   | dev-only placeholder — **change in production** |
| `DATABASE_URL`   | SQLAlchemy database URL                              | `sqlite:///./opportunxt.db`     |
| `CORS_ORIGINS`   | Comma-separated allowed origins, or `*`              | `*`                              |
| `PORT`           | Port the backend listens on                          | `8080` (Cloud Run sets this)    |
| `VITE_API_URL`   | Frontend override for the API base URL (dev only)    | `http://localhost:8000` in dev, same-origin in production |

## 10. Docker

Build and run the whole app (frontend build + backend) in a single container:

```bash
docker build -t opportunxt .
docker run -p 8080:8080 -e SECRET_KEY=your-secret-here opportunxt
```

Then open `http://localhost:8080`.

Or with docker-compose (persists the SQLite database in a named volume):

```bash
docker compose up --build
```

## 11. Google Cloud Run Deployment

1. **Log in to Google Cloud**
   ```bash
   gcloud auth login
   ```
2. **Create or select a project**
   ```bash
   gcloud projects create opportunxt-demo --set-as-default
   # or: gcloud config set project YOUR_EXISTING_PROJECT_ID
   ```
3. **Enable required APIs**
   ```bash
   gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
   ```
4. **Build the container image with Cloud Build**
   ```bash
   gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/opportunxt
   ```
5. **Deploy to Cloud Run**
   ```bash
   gcloud run deploy opportunxt \
     --image gcr.io/YOUR_PROJECT_ID/opportunxt \
     --platform managed \
     --region asia-south1 \
     --allow-unauthenticated \
     --set-env-vars SECRET_KEY=your-strong-random-secret,CORS_ORIGINS=*
   ```
6. **Get the public URL**
   Cloud Run prints a URL such as `https://opportunxt-xxxxxxx-el.a.run.app` after
   deployment — this is your live, shareable demo link.

> Note: this MVP uses SQLite stored inside the container filesystem, which is reset
> on every new revision/deploy. That's fine for a hackathon demo (data reseeds
> automatically on startup). For persistence across deploys, swap `DATABASE_URL` for
> a managed Postgres instance (e.g. Cloud SQL) — no application code changes are
> needed beyond the connection string, since SQLAlchemy abstracts the database.

## 12. Security Notes (MVP scope)

- Passwords are hashed with PBKDF2-HMAC-SHA256 (100,000 iterations) + per-user salt; plaintext passwords are never stored or logged.
- Session tokens are HMAC-signed and expire after 7 days.
- All profile/saved/analytics endpoints require a valid bearer token and verify the requester owns the resource.
- Input is validated with Pydantic models on every endpoint.
- Secrets (`SECRET_KEY`) are read from environment variables, never hard-coded.
- CORS is explicitly configured via `CORS_ORIGINS`.

This is an MVP for a hackathon demo — for production use you would add rate limiting, refresh-token rotation, HTTPS enforcement, and a managed database.

## 13. Demo Flow (Hackathon Presentation Mode)

1. Land on the homepage, search or browse by category
2. Register a new profile (or use the demo account) with skills & interests
3. Land on the Dashboard — see stats, "Closing Soon" alerts, and recommended opportunities
4. Go to Explore, apply filters (category, mode, skill, deadline) and search
5. Open an opportunity's details page — see the match score and "Why this matches you"
6. Save an opportunity, then view it under Saved
7. Click "Apply Now" — opens the real external application link in a new tab
8. Click "Personalize My Opportunities" on the dashboard to re-sort by match %
9. Scroll to the analytics chart — opportunities by category

## 14. Future Scope

- Email/SMS deadline reminders
- College/organization admin panel to submit and manage their own opportunities
- OAuth login (Google/LinkedIn)
- Richer recommendation signals (past application outcomes, peer activity)
- Mobile app (React Native) sharing the same API
- Postgres + managed hosting for durable multi-user data at scale

---

Built as a hackathon MVP. Prioritizes a working, fully functional product with real
persistence, real filtering, and a transparent recommendation engine over unnecessary
complexity.
