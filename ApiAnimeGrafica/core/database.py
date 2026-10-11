from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from core.config import settings

engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,   # detecta conexiones muertas antes de usarlas
    pool_recycle=1800,    # recicla conexiones cada 30 min (MySQL las cierra por inactividad)
    echo=settings.sql_echo,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """Dependencia de FastAPI: una sesión por petición, siempre se cierra."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
