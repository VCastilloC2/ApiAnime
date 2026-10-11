from typing import List, Optional

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from models.anime_model import AnimeModel, GenreModel
from schemas.anime_schema import AnimeCreate, AnimeUpdate, GenreStat

class AnimeRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_all(
        self,
        skip: int = 0,
        limit: int = 10,
        search: Optional[str] = None,
        genre_id: Optional[int] = None,
    ) -> List[AnimeModel]:
        query = self.db.query(AnimeModel).options(joinedload(AnimeModel.genre))
        if search:
            query = query.filter(AnimeModel.title.ilike(f"%{search}%"))
        if genre_id is not None:
            query = query.filter(AnimeModel.genre_id == genre_id)
        return query.order_by(AnimeModel.id).offset(skip).limit(limit).all()

    def get_by_id(self, anime_id: int) -> Optional[AnimeModel]:
        return (
            self.db.query(AnimeModel)
            .options(joinedload(AnimeModel.genre))
            .filter(AnimeModel.id == anime_id)
            .first()
        )

    def create(self, anime: AnimeCreate) -> AnimeModel:
        db_anime = AnimeModel(**anime.model_dump())
        self.db.add(db_anime)
        self.db.commit()
        self.db.refresh(db_anime)
        return db_anime

    def update(self, anime_id: int, data: AnimeUpdate) -> Optional[AnimeModel]:
        db_anime = self.get_by_id(anime_id)
        if db_anime is None:
            return None
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(db_anime, field, value)
        self.db.commit()
        self.db.refresh(db_anime)
        return db_anime

    def delete(self, anime_id: int) -> bool:
        db_anime = self.get_by_id(anime_id)
        if db_anime is None:
            return False
        self.db.delete(db_anime)
        self.db.commit()
        return True

    def stats_by_genre(self) -> List[GenreStat]:
        """Cantidad, rating promedio y episodios totales por género (solo géneros con animes)."""
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


class GenreRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_all(self) -> List[GenreModel]:
        return self.db.query(GenreModel).order_by(GenreModel.name).all()

    def get_by_id(self, genre_id: int) -> Optional[GenreModel]:
        return self.db.query(GenreModel).filter(GenreModel.id == genre_id).first()
