from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import anime_router

app = FastAPI(title="Anime REST API", version="1.0.0")

# CORS abierto para desarrollo (Flutter web / emuladores)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(anime_router.router)

@app.get("/", tags=["Salud"])
def root():
    return {"status": "ok", "docs": "/docs"}