from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field

class AnimeBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=100)
    episodes: int = Field(..., ge=1)
    rating: float = Field(..., ge=0, le=10)
    genre_id: Optional[int] = None

class AnimeCreate(AnimeBase):
    pass

class AnimeUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=100)
    episodes: Optional[int] = Field(None, ge=1)
    rating: Optional[float] = Field(None, ge=0, le=10)
    genre_id: Optional[int] = None

class AnimeResponse(AnimeBase):
    id: int
    genre_name: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

class GenreResponse(BaseModel):
    id: int
    name: str

    model_config = ConfigDict(from_attributes=True)

class GenreStat(BaseModel):
    genre: str
    total_animes: int
    avg_rating: float
    total_episodes: int