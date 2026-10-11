from typing import List, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy.orm import Session

from core.database import get_db
from repositories.anime_repository import AnimeRepository, GenreRepository
from schemas.anime_schema import AnimeCreate, AnimeResponse, AnimeUpdate

router = APIRouter(prefix="/animes", tags=["Animes"])


def get_anime_repo(db: Session = Depends(get_db)) -> AnimeRepository:
    return AnimeRepository(db)


def get_genre_repo(db: Session = Depends(get_db)) -> GenreRepository:
    return GenreRepository(db)


@router.get(
    "",
    response_model=List[AnimeResponse],
    summary="Listar animes (paginado, con búsqueda, filtros y orden)",
)
def list_animes(
    response: Response,
    skip: int = Query(0, ge=0, description="Cuántos registros saltar"),
    limit: int = Query(10, ge=1, le=200, description="Cuántos registros devolver"),
    search: Optional[str] = Query(None, max_length=100, description="Texto dentro del título"),
    genre_id: Optional[int] = Query(None, ge=1),
    min_rating: Optional[float] = Query(None, ge=0, le=10),
    max_rating: Optional[float] = Query(None, ge=0, le=10),
    sort_by: Literal["id", "title", "rating", "episodes", "created_at"] = "id",
    order: Literal["asc", "desc"] = "asc",
    repo: AnimeRepository = Depends(get_anime_repo),
):
    """El total de filas que cumplen el filtro viaja en la cabecera `X-Total-Count`."""
    if min_rating is not None and max_rating is not None and min_rating > max_rating:
        raise HTTPException(status_code=422, detail="min_rating no puede ser mayor que max_rating")
    items, total = repo.get_all(
        skip=skip,
        limit=limit,
        search=search,
        genre_id=genre_id,
        min_rating=min_rating,
        max_rating=max_rating,
        sort_by=sort_by,
        order=order,
    )
    response.headers["X-Total-Count"] = str(total)
    return items


@router.get("/{anime_id}", response_model=AnimeResponse, summary="Obtener un anime por id")
def get_anime(anime_id: int, repo: AnimeRepository = Depends(get_anime_repo)):
    anime = repo.get_by_id(anime_id)
    if anime is None:
        raise HTTPException(status_code=404, detail="Anime no encontrado")
    return anime


@router.post("", response_model=AnimeResponse, status_code=201, summary="Crear un anime")
def create_anime(
    anime: AnimeCreate,
    response: Response,
    repo: AnimeRepository = Depends(get_anime_repo),
    genres: GenreRepository = Depends(get_genre_repo),
):
    if anime.genre_id is not None and genres.get_by_id(anime.genre_id) is None:
        raise HTTPException(status_code=400, detail="El género indicado no existe")
    created = repo.create(anime)
    response.headers["Location"] = f"/animes/{created.id}"
    return created


@router.put("/{anime_id}", response_model=AnimeResponse, summary="Actualizar un anime")
@router.patch("/{anime_id}", response_model=AnimeResponse, include_in_schema=False)
def update_anime(
    anime_id: int,
    data: AnimeUpdate,
    repo: AnimeRepository = Depends(get_anime_repo),
    genres: GenreRepository = Depends(get_genre_repo),
):
    """Actualización parcial: envía solo los campos que cambian (PUT y PATCH hacen lo mismo)."""
    if data.genre_id is not None and genres.get_by_id(data.genre_id) is None:
        raise HTTPException(status_code=400, detail="El género indicado no existe")
    anime = repo.update(anime_id, data)
    if anime is None:
        raise HTTPException(status_code=404, detail="Anime no encontrado")
    return anime


@router.delete("/{anime_id}", status_code=204, summary="Eliminar un anime")
def delete_anime(anime_id: int, repo: AnimeRepository = Depends(get_anime_repo)):
    if not repo.delete(anime_id):
        raise HTTPException(status_code=404, detail="Anime no encontrado")
    return Response(status_code=204)
