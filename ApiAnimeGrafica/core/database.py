import os

from sqlalchemy import create_engine
from sqlalchemy.pool import NullPool
from sqlalchemy.orm import declarative_base, sessionmaker

from core.config import settings

# En Vercel (serverless) NO se debe mantener un pool: cada invocación es efímera y
# Clever Cloud (plan gratis) solo permite ~5 conexiones simultáneas. NullPool abre y cierra por petición.
_pool_args = (
    {"poolclass": NullPool}
    if os.getenv("VERCEL")
    else {"pool_pre_ping": True, "pool_recycle": 1800}
)

engine = create_engine(
    settings.database_url,
    echo=settings.sql_echo,
    **_pool_args,
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
