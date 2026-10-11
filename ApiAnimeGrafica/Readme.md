# Anime REST API (FastAPI + MySQL)

## 1. Configuración
1. Copia `.env.example` como `.env` y escribe tus datos reales de MySQL.
2. Crea las tablas `genres` y `animes` en `db_anime` (tu script SQL).
3. Instala dependencias: `pip install -r requirements.txt`

deactivate
Remove-Item -Recurse -Force venv
python -m venv venv
.\venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt

python check_db.py
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

> Ojo: `--reload` solo reinicia cuando cambias archivos `.py`. Si editas el `.env`
> debes parar uvicorn (Ctrl+C) y volver a arrancarlo.

Documentación interactiva: http://localhost:8000/docs  |  Salud: http://localhost:8000/health

## 4. Endpoints
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/animes` | Lista paginada. Query: `skip, limit, search, genre_id, min_rating, max_rating, sort_by, order`. Total en cabecera `X-Total-Count` |
| GET | `/animes/{id}` | Un anime |
| POST | `/animes` | Crear (201) |
| PUT / PATCH | `/animes/{id}` | Actualización parcial |
| DELETE | `/animes/{id}` | Eliminar (204) |
| GET/POST | `/genres` | Listar / crear género |
| GET/PUT/DELETE | `/genres/{id}` | Ver / renombrar / eliminar género |
| GET | `/stats/summary` | Totales generales |
| GET | `/stats/by-genre` | Animes, rating promedio y episodios por género |
| GET | `/stats/top-rated?limit=10` | Mejor calificados |
| GET | `/stats/rating-distribution` | Animes por rango de rating (0-2 … 8-10) |
| GET | `/health` | API + base de datos |

## 5. Pruebas rápidas (PowerShell)
    curl.exe "http://localhost:8000/animes?limit=5&search=hell"
    curl.exe -X POST http://localhost:8000/animes -H "Content-Type: application/json" -d "{\"title\":\"Hellsing\",\"episodes\":13,\"rating\":7.9,\"genre_id\":1}"

## 6. Pruebas automáticas (usan SQLite en memoria, no tocan tu MySQL)
    pip install -r requirements-dev.txt
    pytest

## 7. URL base desde Flutter
- Emulador Android: `http://10.0.2.2:8000`
- Simulador iOS / Flutter web / Windows: `http://localhost:8000`
- Celular físico: `http://IP_DE_TU_PC:8000` (mismo Wi-Fi; permite el puerto 8000 en el firewall de Windows)