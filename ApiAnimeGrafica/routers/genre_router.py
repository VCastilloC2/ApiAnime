from typing import List

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session

from core.database import get_db
from repositories.anime_repository import GenreRepository
from schemas.anime_schema import GenreCreate, GenreResponse, GenreUpdate

router = APIRouter(prefix="/genres", tags=["Géneros"])


def get_genre_repo(db: Session = Depends(get_db)) -> GenreRepository:
    return GenreRepository(db)


@router.get("", response_model=List[GenreResponse], summary="Listar géneros")
def list_genres(repo: GenreRepository = Depends(get_genre_repo)):
    return repo.get_all()


@router.get("/{genre_id}", response_model=GenreResponse, summary="Obtener un género por id")
def get_genre(genre_id: int, repo: GenreRepository = Depends(get_genre_repo)):
    genre = repo.get_by_id(genre_id)
    if genre is None:
        raise HTTPException(status_code=404, detail="Género no encontrado")
    return genre


@router.post("", response_model=GenreResponse, status_code=201, summary="Crear un género")
def create_genre(data: GenreCreate, repo: GenreRepository = Depends(get_genre_repo)):
    if repo.get_by_name(data.name) is not None:
        raise HTTPException(status_code=409, detail="Ya existe un género con ese nombre")
    return repo.create(data)


@router.put("/{genre_id}", response_model=GenreResponse, summary="Renombrar un género")
def update_genre(genre_id: int, data: GenreUpdate, repo: GenreRepository = Depends(get_genre_repo)):
    existing = repo.get_by_name(data.name)
    if existing is not None and existing.id != genre_id:
        raise HTTPException(status_code=409, detail="Ya existe un género con ese nombre")
    genre = repo.update(genre_id, data)
    if genre is None:
        raise HTTPException(status_code=404, detail="Género no encontrado")
    return genre


@router.delete("/{genre_id}", status_code=204, summary="Eliminar un género (sus animes quedan sin género)")
def delete_genre(genre_id: int, repo: GenreRepository = Depends(get_genre_repo)):
    if not repo.delete(genre_id):
        raise HTTPException(status_code=404, detail="Género no encontrado")
    return Response(status_code=204)
