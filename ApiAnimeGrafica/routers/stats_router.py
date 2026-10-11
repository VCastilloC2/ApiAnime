from typing import List

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from core.database import get_db
from repositories.anime_repository import AnimeRepository
from schemas.anime_schema import AnimeResponse, GenreStat, RatingBucket, StatsSummary

router = APIRouter(prefix="/stats", tags=["Estadísticas"])


def get_anime_repo(db: Session = Depends(get_db)) -> AnimeRepository:
    return AnimeRepository(db)


@router.get("/summary", response_model=StatsSummary, summary="Totales generales (tarjetas del dashboard)")
def summary(repo: AnimeRepository = Depends(get_anime_repo)):
    return repo.stats_summary()


@router.get("/by-genre", response_model=List[GenreStat], summary="Animes, rating promedio y episodios por género")
def by_genre(repo: AnimeRepository = Depends(get_anime_repo)):
    return repo.stats_by_genre()


@router.get("/top-rated", response_model=List[AnimeResponse], summary="Animes mejor calificados")
def top_rated(limit: int = Query(10, ge=1, le=50), repo: AnimeRepository = Depends(get_anime_repo)):
    return repo.top_rated(limit)


@router.get("/rating-distribution", response_model=List[RatingBucket], summary="Cantidad de animes por rango de rating")
def rating_distribution(repo: AnimeRepository = Depends(get_anime_repo)):
    return repo.rating_distribution()
