"""Convierte errores de base de datos en respuestas JSON claras (y no en un 500 mudo)."""
import logging

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import DataError, DBAPIError, IntegrityError, OperationalError

from core.config import settings

logger = logging.getLogger("anime_api")

# Códigos de MySQL que significan "no pude entrar / no encuentro la BD"
CONNECTION_HINTS = {
    1044: "El usuario no tiene permisos sobre esa base de datos.",
    1045: "Usuario o contraseña incorrectos: revisa DB_USER y DB_PASSWORD en .env y reinicia uvicorn.",
    1049: "La base de datos indicada en DB_NAME no existe.",
    2002: "No se pudo conectar al servidor MySQL (¿está encendido?).",
    2003: "No se pudo conectar al servidor MySQL: revisa DB_HOST y DB_PORT, y que el servicio esté activo.",
    2006: "MySQL cerró la conexión (server has gone away).",
    2013: "Se perdió la conexión con MySQL durante la consulta.",
}


def _errno(exc: DBAPIError):
    return getattr(getattr(exc, "orig", None), "errno", None)


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(IntegrityError)
    async def integrity_error(request: Request, exc: IntegrityError):
        logger.warning("IntegrityError en %s %s: %s", request.method, request.url.path, exc.orig)
        return JSONResponse(
            status_code=409,
            content={"detail": "Dato duplicado o referencia inválida (restricción de la base de datos)."},
        )

    @app.exception_handler(DataError)
    async def data_error(request: Request, exc: DataError):
        logger.warning("DataError en %s %s: %s", request.method, request.url.path, exc.orig)
        return JSONResponse(status_code=422, content={"detail": "Valor fuera de rango o con formato inválido."})

    @app.exception_handler(DBAPIError)
    async def db_error(request: Request, exc: DBAPIError):
        errno = _errno(exc)
        is_connection = isinstance(exc, OperationalError) or errno in CONNECTION_HINTS
        hint = CONNECTION_HINTS.get(errno, "")
        logger.error(
            "Error de BD en %s %s [errno=%s]: %s | %s",
            request.method, request.url.path, errno, getattr(exc, "orig", exc), hint,
        )
        content = {
            "detail": "No se pudo comunicar con la base de datos."
            if is_connection
            else "Error interno de base de datos."
        }
        if settings.debug and hint:
            content["hint"] = hint
        return JSONResponse(status_code=503 if is_connection else 500, content=content)
