from typing import List, Optional, Tuple

from sqlalchemy import and_, case, func
from sqlalchemy.orm import Session, joinedload

from models.anime_model import AnimeModel, GenreModel
from schemas.anime_schema import (
    AnimeCreate,
    AnimeUpdate,
    GenreCreate,
    GenreStat,
    GenreUpdate,
    RatingBucket,
    StatsSummary,
)

SORTABLE = {
    "id": AnimeModel.id,
    "title": AnimeModel.title,
    "rating": AnimeModel.rating,
    "episodes": AnimeModel.episodes,
    "created_at": AnimeModel.created_at,
}

RATING_BUCKETS = [(0, 2, "0-2"), (2, 4, "2-4"), (4, 6, "4-6"), (6, 8, "6-8"), (8, 10, "8-10")]


class AnimeRepository:
    def __init__(self, db: Session):
        self.db = db

    # ----- lectura -----
    def _filtered(self, search, genre_id, min_rating, max_rating):
        query = self.db.query(AnimeModel)
        if search and search.strip():
            # autoescape: si el usuario escribe % o _ se trata como texto normal
            query = query.filter(
                func.lower(AnimeModel.title).contains(search.strip().lower(), autoescape=True)
            )
        if genre_id is not None:
            query = query.filter(AnimeModel.genre_id == genre_id)
        if min_rating is not None:
            query = query.filter(AnimeModel.rating >= min_rating)
        if max_rating is not None:
            query = query.filter(AnimeModel.rating <= max_rating)
        return query

    def get_all(
        self,
        skip: int = 0,
        limit: int = 10,
        search: Optional[str] = None,
        genre_id: Optional[int] = None,
        min_rating: Optional[float] = None,
        max_rating: Optional[float] = None,
        sort_by: str = "id",
        order: str = "asc",
    ) -> Tuple[List[AnimeModel], int]:
        """Devuelve (página de animes, total de filas que cumplen el filtro)."""
        base = self._filtered(search, genre_id, min_rating, max_rating)
        total = base.with_entities(func.count(AnimeModel.id)).scalar() or 0

        column = SORTABLE.get(sort_by, AnimeModel.id)
        ordering = [column.desc() if order == "desc" else column.asc()]
        if sort_by != "id":
            ordering.append(AnimeModel.id)  # desempate estable para paginar

        items = (
            base.options(joinedload(AnimeModel.genre))
            .order_by(*ordering)
            .offset(skip)
            .limit(limit)
            .all()
        )
        return items, int(total)

    def get_by_id(self, anime_id: int) -> Optional[AnimeModel]:
        return (
            self.db.query(AnimeModel)
            .options(joinedload(AnimeModel.genre))
            .filter(AnimeModel.id == anime_id)
            .first()
        )

    # ----- escritura -----
    def create(self, anime: AnimeCreate) -> AnimeModel:
        db_anime = AnimeModel(**anime.model_dump())
        self.db.add(db_anime)
        self.db.commit()
        return self.get_by_id(db_anime.id)  # recarga con el género ya cargado

    def update(self, anime_id: int, data: AnimeUpdate) -> Optional[AnimeModel]:
        db_anime = self.get_by_id(anime_id)
        if db_anime is None:
            return None
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(db_anime, field, value)
        self.db.commit()
        return self.get_by_id(anime_id)

    def delete(self, anime_id: int) -> bool:
        db_anime = self.get_by_id(anime_id)
        if db_anime is None:
            return False
        self.db.delete(db_anime)
        self.db.commit()
        return True

    # ----- estadísticas -----
    def stats_by_genre(self) -> List[GenreStat]:
        rows = (
            self.db.query(
                GenreModel.name,
                func.count(AnimeModel.id),
                func.avg(AnimeModel.rating),
                func.sum(AnimeModel.episodes),
            )
            .join(AnimeModel, AnimeModel.genre_id == GenreModel.id)
            .group_by(GenreModel.id, GenreModel.name)
            .order_by(func.count(AnimeModel.id).desc(), GenreModel.name)
            .all()
        )
        return [
            GenreStat(
                genre=name,
                total_animes=int(total),
                avg_rating=round(float(avg), 2),
                total_episodes=int(episodes),
            )
            for name, total, avg, episodes in rows
        ]

    def stats_summary(self) -> StatsSummary:
        total, avg, episodes = self.db.query(
            func.count(AnimeModel.id),
            func.avg(AnimeModel.rating),
            func.coalesce(func.sum(AnimeModel.episodes), 0),
        ).one()
        total_genres = self.db.query(func.count(GenreModel.id)).scalar() or 0
        without_genre = (
            self.db.query(func.count(AnimeModel.id)).filter(AnimeModel.genre_id.is_(None)).scalar() or 0
        )
        return StatsSummary(
            total_animes=int(total),
            total_genres=int(total_genres),
            animes_without_genre=int(without_genre),
            avg_rating=round(float(avg), 2) if avg is not None else 0.0,
            total_episodes=int(episodes),
        )

    def top_rated(self, limit: int = 10) -> List[AnimeModel]:
        return (
            self.db.query(AnimeModel)
            .options(joinedload(AnimeModel.genre))
            .order_by(AnimeModel.rating.desc(), AnimeModel.id)
            .limit(limit)
            .all()
        )

    def rating_distribution(self) -> List[RatingBucket]:
        columns = []
        for low, high, _label in RATING_BUCKETS:
            upper = AnimeModel.rating <= high if high == 10 else AnimeModel.rating < high
            cond = and_(AnimeModel.rating >= low, upper)
            columns.append(func.coalesce(func.sum(case((cond, 1), else_=0)), 0))
        row = self.db.query(*columns).one()
        return [
            RatingBucket(label=label, total=int(count))
            for (_l, _h, label), count in zip(RATING_BUCKETS, row)
        ]


class GenreRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_all(self) -> List[GenreModel]:
        return self.db.query(GenreModel).order_by(GenreModel.name).all()

    def get_by_id(self, genre_id: int) -> Optional[GenreModel]:
        return self.db.query(GenreModel).filter(GenreModel.id == genre_id).first()

    def get_by_name(self, name: str) -> Optional[GenreModel]:
        return (
            self.db.query(GenreModel)
            .filter(func.lower(GenreModel.name) == name.strip().lower())
            .first()
        )

    def create(self, data: GenreCreate) -> GenreModel:
        genre = GenreModel(name=data.name)
        self.db.add(genre)
        self.db.commit()
        self.db.refresh(genre)
        return genre

    def update(self, genre_id: int, data: GenreUpdate) -> Optional[GenreModel]:
        genre = self.get_by_id(genre_id)
        if genre is None:
            return None
        genre.name = data.name
        self.db.commit()
        self.db.refresh(genre)
        return genre

    def delete(self, genre_id: int) -> bool:
        genre = self.get_by_id(genre_id)
        if genre is None:
            return False
        self.db.delete(genre)  # los animes quedan con genre_id = NULL (ON DELETE SET NULL)
        self.db.commit()
        return True
