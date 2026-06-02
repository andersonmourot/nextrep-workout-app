from datetime import datetime, timezone

from sqlalchemy import DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    email: Mapped[str] = mapped_column(String, unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String, nullable=False)
    # JSON document holding the user's app data (programs, logs, settings, etc.)
    data: Mapped[str] = mapped_column(Text, nullable=False, default="{}")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
