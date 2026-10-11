"""Configuración central. Lee el archivo .env UNA sola vez y valida lo obligatorio."""
import os
from dataclasses import dataclass
from pathlib import Path
from typing import List

from dotenv import load_dotenv
from sqlalchemy.engine import URL

BASE_DIR = Path(__file__).resolve().parent.parent
ENV_FILE = BASE_DIR / ".env"

# override=True -> el .env MANDA sobre variables de entorno de Windows que se llamen igual.
# (Sin esto, un DB_PASSWORD viejo definido en el sistema ignoraba tu .env sin avisar.)
load_dotenv(ENV_FILE, override=True)


def _required(name: str) -> str:
    value = os.getenv(name)
    if value is None or value.strip() == "":
        raise RuntimeError(
            f"Falta la variable {name}. Créala en {ENV_FILE} (mira .env.example)."
        )
    return value.strip()


def _bool(name: str, default: bool = False) -> bool:
    return os.getenv(name, str(default)).strip().lower() in {"1", "true", "yes", "si", "sí"}


@dataclass(frozen=True)
class Settings:
    db_user: str
    db_password: str
    db_host: str
    db_port: int
    db_name: str
    cors_origins: List[str]
    debug: bool
    sql_echo: bool

    @property
    def database_url(self) -> URL:
        # URL.create escapa solo los caracteres raros del password (@, #, %, etc.)
        return URL.create(
            drivername="mysql+mysqlconnector",
            username=self.db_user,
            password=self.db_password or None,
            host=self.db_host,
            port=self.db_port,
            database=self.db_name,
        )

    @property
    def safe_database_url(self) -> str:
        """URL para mostrar en logs, con el password oculto."""
        return self.database_url.render_as_string(hide_password=True)


def load_settings() -> Settings:
    origins = [o.strip() for o in os.getenv("CORS_ORIGINS", "*").split(",") if o.strip()]
    return Settings(
        db_user=_required("DB_USER"),
        db_password=os.getenv("DB_PASSWORD", "").strip(),  # puede ser vacío (XAMPP)
        db_host=_required("DB_HOST"),
        db_port=int(os.getenv("DB_PORT", "3306")),
        db_name=_required("DB_NAME"),
        cors_origins=origins or ["*"],
        debug=_bool("DEBUG"),
        sql_echo=_bool("SQL_ECHO"),
    )


settings = load_settings()
