import os

# Valores mínimos para poder importar la app sin un MySQL real.
for key, value in {"DB_USER": "test", "DB_PASSWORD": "test", "DB_HOST": "localhost", "DB_NAME": "test"}.items():
    os.environ.setdefault(key, value)

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import models.anime_model  # noqa: F401  (registra las tablas en Base)
from core.database import Base, get_db
from main import app


@pytest.fixture()
def client():
    """Cliente de pruebas con SQLite en memoria (no toca tu MySQL)."""
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine, autoflush=False, autocommit=False)

    def override_get_db():
        db = Session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)  # sin "with": no ejecuta el lifespan (que probaría MySQL real)
    app.dependency_overrides.clear()
