import os


class Config:
    HOST = os.getenv("APP_HOST", "127.0.0.1")
    PORT = int(os.getenv("APP_PORT", "5000"))
    DEBUG = os.getenv("APP_DEBUG", "true").lower() == "true"
    SECRET_KEY = os.getenv("APP_SECRET_KEY", "pet-system-dev-secret")

    DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
    DB_PORT = int(os.getenv("DB_PORT", "3306"))
    DB_USER = os.getenv("DB_USER", "root")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")
    DB_NAME = os.getenv("DB_NAME", "pet")
