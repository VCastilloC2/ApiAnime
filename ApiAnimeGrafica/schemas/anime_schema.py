from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


def _clean_text(value: Optional[str], label: str) -> Optional[str]:
    if value is None:
        return value
    value = value.strip()
    if not value:
        raise ValueError(f"{label} no puede estar vacío")
    return value


# ---------- Animes ----------
class AnimeBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=100, examples=["Hellsing Ultimate"])
    episodes: int = Field(..., ge=1, le=100000, examples=[10])
    rating: float = Field(..., ge=0, le=10, examples=[8.4])
    genre_id: Optional[int] = Field(None, ge=1, examples=[1])

    @field_validator("title")
    @classmethod
    def _title(cls, v):
        return _clean_text(v, "El título")

    @field_validator("rating")
    @classmethod
    def _rating(cls, v):
        return round(v, 1)  # la columna es DECIMAL(3,1)


class AnimeCreate(AnimeBase):
    pass


class AnimeUpdate(BaseModel):
    """Actualización parcial: solo se cambian los campos que envíes."""

    title: Optional[str] = Field(None, min_length=1, max_length=100)
    episodes: Optional[int] = Field(None, ge=1, le=100000)
    rating: Optional[float] = Field(None, ge=0, le=10)
    genre_id: Optional[int] = Field(None, ge=1)  # envía null para quitar el género

    @field_validator("title")
    @classmethod
    def _title(cls, v):
        return _clean_text(v, "El título")

    @field_validator("rating")
    @classmethod
    def _rating(cls, v):
        return None if v is None else round(v, 1)

    @model_validator(mode="after")
    def _not_empty_not_null(self):
        if not self.model_fields_set:
            raise ValueError("Envía al menos un campo para actualizar")
        for name in ("title", "episodes", "rating"):  # columnas NOT NULL
            if name in self.model_fields_set and getattr(self, name) is None:
                raise ValueError(f"'{name}' no puede ser null")
        return self


class AnimeResponse(AnimeBase):
    id: int
    genre_name: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


# ---------- Géneros ----------
class GenreBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=50, examples=["Acción"])

    @field_validator("name")
    @classmethod
    def _name(cls, v):
        return _clean_text(v, "El nombre")


class GenreCreate(GenreBase):
    pass


class GenreUpdate(GenreBase):
    pass


class GenreResponse(BaseModel):
    id: int
    name: str

    model_config = ConfigDict(from_attributes=True)


# ---------- Estadísticas (para los gráficos de Flutter) ----------
class GenreStat(BaseModel):
    genre: str
    total_animes: int
    avg_rating: float
    total_episodes: int


class StatsSummary(BaseModel):
    total_animes: int
    total_genres: int
    animes_without_genre: int
    avg_rating: float
    total_episodes: int


class RatingBucket(BaseModel):
    label: str
    total: int