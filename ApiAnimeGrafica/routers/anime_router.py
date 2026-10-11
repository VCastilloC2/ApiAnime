from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy.orm import Session

from core.database import get_db
from repositories.anime_repository import AnimeRepository, GenreRepository
from schemas.anime_schema import (
    AnimeCreate,
    AnimeResponse,
    AnimeUpdate,
    GenreResponse,
    GenreStat,
)

router = APIRouter()

def get_anime_repo(db: Session = Depends(get_db)) -> AnimeRepository:
    return AnimeRepository(db)

def get_genre_repo(db: Session = Depends(get_db)) -> GenreRepository:
    return GenreRepository(db)

# ---------- Animes ----------
@router.get("/animes", response_model=List[AnimeResponse], tags=["Animes"])
def list_animes(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=200),
    search: Optional[str] = None,
    genre_id: Optional[int] = None,
    repo: AnimeRepository = Depends(get_anime_repo),
):
    return repo.get_all(skip=skip, limit=limit, search=search, genre_id=genre_id)


@router.get("/animes/{anime_id}", response_model=AnimeResponse, tags=["Animes"])
def get_anime(anime_id: int, repo: AnimeRepository = Depends(get_anime_repo)):
    anime = repo.get_by_id(anime_id)
    if anime is None:
        raise HTTPException(status_code=404, detail="Anime no encontrado")
    return anime

@router.post("/animes", response_model=AnimeResponse, status_code=201, tags=["Animes"])
def create_anime(
    anime: AnimeCreate,
    repo: AnimeRepository = Depends(get_anime_repo),
    genres: GenreRepository = Depends(get_genre_repo),
):
    if anime.genre_id is not None and genres.get_by_id(anime.genre_id) is None:
        raise HTTPException(status_code=400, detail="El género indicado no existe")
    return repo.create(anime)

@router.put("/animes/{anime_id}", response_model=AnimeResponse, tags=["Animes"])
def update_anime(
    anime_id: int,
    data: AnimeUpdate,
    repo: AnimeRepository = Depends(get_anime_repo),
    genres: GenreRepository = Depends(get_genre_repo),
):
    if data.genre_id is not None and genres.get_by_id(data.genre_id) is None:
        raise HTTPException(status_code=400, detail="El género indicado no existe")
    anime = repo.update(anime_id, data)
    if anime is None:
        raise HTTPException(status_code=404, detail="Anime no encontrado")
    return anime

@router.delete("/animes/{anime_id}", status_code=204, tags=["Animes"])
def delete_anime(anime_id: int, repo: AnimeRepository = Depends(get_anime_repo)):
    if not repo.delete(anime_id):
        raise HTTPException(status_code=404, detail="Anime no encontrado")
    return Response(status_code=204)

# ---------- Géneros ----------
@router.get("/genres", response_model=List[GenreResponse], tags=["Géneros"])
def list_genres(repo: GenreRepository = Depends(get_genre_repo)):
    return repo.get_all()

# ---------- Estadísticas (para los gráficos de Flutter) ----------
@router.get("/stats/by-genre", response_model=List[GenreStat], tags=["Estadísticas"])
def stats_by_genre(repo: AnimeRepository = Depends(get_anime_repo)):
    return repo.stats_by_genre()