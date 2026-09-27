# ---------- Stage 1: build the frontend ----------
FROM node:20-alpine AS frontend-build
WORKDIR /app/frontend
COPY frontend/package.json ./
RUN npm install
COPY frontend/ ./
RUN npm run build

# ---------- Stage 2: backend + serve built frontend ----------
FROM python:3.11-slim AS final
WORKDIR /app

# Install backend dependencies
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source
COPY backend/app ./app

# Copy built frontend into /app/static (served by FastAPI)
COPY --from=frontend-build /app/frontend/dist ./static

# Cloud Run provides PORT; default to 8080 for local docker run
ENV PORT=8080
EXPOSE 8080

# Persist the SQLite database in a writable location
ENV DATABASE_URL=sqlite:////app/data/opportunxt.db
RUN mkdir -p /app/data

CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT}
