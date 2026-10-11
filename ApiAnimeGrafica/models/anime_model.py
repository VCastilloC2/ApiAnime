from sqlalchemy import TIMESTAMP, Column, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.orm import relationship

from core.database import Base


class GenreModel(Base):
    __tablename__ = "tb_genres"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50), nullable=False, unique=True)

    # passive_deletes: deja que MySQL aplique ON DELETE SET NULL de la llave foránea
    animes = relationship("AnimeModel", back_populates="genre", passive_deletes=True)


class AnimeModel(Base):
    __tablename__ = "tb_animes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String(100), nullable=False)
    episodes = Column(Integer, nullable=False)
    rating = Column(Numeric(3, 1, asdecimal=False), nullable=False)
    genre_id = Column(Integer, ForeignKey("tb_genres.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

    genre = relationship("GenreModel", back_populates="animes")

    @property
    def genre_name(self):
        return self.genre.name if self.genre else None
