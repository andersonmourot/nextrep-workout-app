from datetime import datetime, timezone

from sqlalchemy import BigInteger, Boolean, DateTime, String, Text
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


class Follow(Base):
    """A directed follow edge: follower_id follows following_id."""

    __tablename__ = "follows"

    follower_id: Mapped[str] = mapped_column(String, primary_key=True, index=True)
    following_id: Mapped[str] = mapped_column(String, primary_key=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class SharedProgram(Base):
    """Canonical, cross-account store for a user-created program.

    All accounts that add the program reference it by this same id, so an
    edit by the owner (or any collaborator, when collaborative) propagates to
    everyone who has it.
    """

    __tablename__ = "shared_programs"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    owner_id: Mapped[str] = mapped_column(String, index=True, nullable=False)
    owner_name: Mapped[str] = mapped_column(String, nullable=False, default="")
    collaborative: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    # Full program JSON (source of truth for content).
    data: Mapped[str] = mapped_column(Text, nullable=False, default="{}")
    # Epoch-ms of the last edit; clients pull when this exceeds their copy.
    version: Mapped[int] = mapped_column(BigInteger, nullable=False, default=0)
    updated_by: Mapped[str] = mapped_column(String, nullable=False, default="")
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class ProgramMember(Base):
    """Records that a user has added a shared program (and may edit it when
    the program is collaborative). The owner is always a member."""

    __tablename__ = "program_members"

    program_id: Mapped[str] = mapped_column(String, primary_key=True, index=True)
    user_id: Mapped[str] = mapped_column(String, primary_key=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class SharedExercise(Base):
    """Canonical, cross-account store for a user-created (shared) exercise.

    All accounts that add the exercise reference it by this same id, so an edit
    by the owner (or any collaborator, when collaborative) propagates to
    everyone who has it.
    """

    __tablename__ = "shared_exercises"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    owner_id: Mapped[str] = mapped_column(String, index=True, nullable=False)
    owner_name: Mapped[str] = mapped_column(String, nullable=False, default="")
    collaborative: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    # Full exercise JSON (source of truth for content).
    data: Mapped[str] = mapped_column(Text, nullable=False, default="{}")
    # Epoch-ms of the last edit; clients pull when this exceeds their copy.
    version: Mapped[int] = mapped_column(BigInteger, nullable=False, default=0)
    updated_by: Mapped[str] = mapped_column(String, nullable=False, default="")
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class ExerciseMember(Base):
    """Records that a user has added a shared exercise (and may edit it when the
    exercise is collaborative). The owner is always a member."""

    __tablename__ = "exercise_members"

    exercise_id: Mapped[str] = mapped_column(String, primary_key=True, index=True)
    user_id: Mapped[str] = mapped_column(String, primary_key=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
