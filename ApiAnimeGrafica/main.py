import logging
import time
from contextlib import asynccontextmanager
from fastapi import Depends, FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session
from core.config import settings
from core.database import engine, get_db
from core.exceptions import CONNECTION_HINTS, _errno, register_exception_handlers
from routers import anime_router, genre_router, stats_router

logging.basicConfig(level=logging.INFO, format="%(levelname)s:     %(name)s - %(message)s")
logger = logging.getLogger("anime_api")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Al arrancar probamos MySQL y avisamos CLARO si falla (la API sigue viva para ver /docs).
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("Conexión a MySQL OK -> %s", settings.safe_database_url)
    except SQLAlchemyError as exc:
        errno = _errno(exc)
        logger.error("NO se pudo conectar a MySQL -> %s", settings.safe_database_url)
        logger.error("Motivo: %s", getattr(exc, "orig", exc))
        if errno in CONNECTION_HINTS:
            logger.error("Pista: %s", CONNECTION_HINTS[errno])
    yield
    engine.dispose()


app = FastAPI(
    title="Anime REST API",
    version="2.0.0",
    description="API REST de animes y géneros (FastAPI + SQLAlchemy + MySQL) para la app Flutter.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Total-Count", "Location", "X-Process-Time-ms"],  # para que Flutter web las lea
)


@app.middleware("http")
async def add_process_time(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    response.headers["X-Process-Time-ms"] = f"{(time.perf_counter() - start) * 1000:.1f}"
    return response


register_exception_handlers(app)

app.include_router(anime_router.router)
app.include_router(genre_router.router)
app.include_router(stats_router.router)


@app.get("/", tags=["Salud"], summary="Estado de la API")
def root():
    return {"status": "ok", "docs": "/docs", "health": "/health"}


@app.get("/health", tags=["Salud"], summary="Estado de la API y de la base de datos")
def health(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))  # si MySQL falla, el handler responde 503 con un JSON claro
    return {"status": "ok", "database": "up"}


@app.get("/favicon.ico", include_in_schema=False)
def favicon():
    return Response(status_code=204)