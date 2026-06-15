import os

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker


def _db_url() -> str:
    """Resolve the database URL.

    Prefers SMELLIS_DB_PATH / DATABASE_URL env vars; otherwise stores the
    SQLite file on the /data volume when present (Fly.io), else locally.
    """
    explicit = os.environ.get("DATABASE_URL")
    if explicit:
        return explicit
    path = os.environ.get("SMELLIS_DB_PATH")
    if not path:
        path = "/data/smellis.db" if os.path.isdir("/data") else "./smellis.db"
    return f"sqlite:///{path}"


engine = create_engine(
    _db_url(),
    connect_args={"check_same_thread": False},
)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
