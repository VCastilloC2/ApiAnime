"""Diagnóstico de la conexión a MySQL, sin FastAPI de por medio.

Uso (con el venv activado, desde la carpeta del proyecto):
    python check_db.py
"""
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from core.config import ENV_FILE, settings
from core.database import engine
from core.exceptions import CONNECTION_HINTS, _errno


def main() -> int:
    print(f"Archivo .env leído : {ENV_FILE}  (existe: {ENV_FILE.exists()})")
    print(f"Conectando a       : {settings.safe_database_url}")
    print(f"Largo de DB_PASSWORD leído: {len(settings.db_password)} caracteres")
    try:
        with engine.connect() as conn:
            print("Versión de MySQL   :", conn.execute(text("SELECT VERSION()")).scalar())
            print("Base de datos      :", conn.execute(text("SELECT DATABASE()")).scalar())
            for table in ("tb_genres", "tb_animes"):
                total = conn.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar()
                print(f"Filas en {table:<7}  :", total)
        print("\nCONEXIÓN OK: ahora sí puedes arrancar uvicorn.")
        return 0
    except SQLAlchemyError as exc:
        errno = _errno(exc)
        print("\nFALLÓ la conexión:", getattr(exc, "orig", exc))
        if errno in CONNECTION_HINTS:
            print("Pista:", CONNECTION_HINTS[errno])
        return 1


if __name__ == "__main__":
    raise SystemExit(main())