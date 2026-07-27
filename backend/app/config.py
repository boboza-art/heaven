"""Application configuration using pydantic-settings."""

import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict

# Load .env file
env_path = Path(__file__).resolve().parent.parent.parent / ".env"
if env_path.exists():
    load_dotenv(env_path)


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(extra="ignore", env_file=".env")

    # Database
    database_url: str = os.getenv(
        "DATABASE_URL",
        "postgresql+psycopg2://haven:haven_dev@localhost:5432/haven",
    )

    # JWT
    jwt_secret_key: str = os.getenv("JWT_SECRET_KEY", "")
    jwt_algorithm: str = os.getenv("JWT_ALGORITHM", "HS256")
    access_token_expire_minutes: int = int(
        os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "10080")  # 7 days
    )
    refresh_token_expire_days: int = int(
        os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30")
    )

    # Server
    host: str = os.getenv("HOST", "0.0.0.0")
    port: int = int(os.getenv("PORT", "8000"))

    # CORS — stored as comma-separated string, split at runtime
    cors_origins_str: str = os.getenv(
        "CORS_ORIGINS", "http://localhost:3000,http://localhost:8080"
    )

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.cors_origins_str.split(",") if o.strip()]

    # LLM / AI
    llm_api_key: str = os.getenv("LLM_API_KEY", "")
    llm_api_base: str = os.getenv(
        "LLM_API_BASE", "https://api.openai.com/v1"
    )
    llm_model: str = os.getenv("LLM_MODEL", "gpt-4o-mini")
    llm_temperature: float = float(os.getenv("LLM_TEMPERATURE", "0.7"))
    llm_max_tokens: int = int(os.getenv("LLM_MAX_TOKENS", "500"))
    llm_timeout_seconds: int = int(os.getenv("LLM_TIMEOUT_SECONDS", "30"))
    # When True, fall back to mock responses if LLM call fails
    llm_fallback_to_mock: bool = os.getenv(
        "LLM_FALLBACK_TO_MOCK", "true"
    ).lower() in ("true", "1", "yes")
    # Number of recent messages to include as context
    llm_context_window: int = int(os.getenv("LLM_CONTEXT_WINDOW", "10"))

    # Memory System
    memory_extraction_enabled: bool = os.getenv(
        "MEMORY_EXTRACTION_ENABLED", "true"
    ).lower() in ("true", "1", "yes")
    memory_max_in_prompt: int = int(os.getenv("MEMORY_MAX_IN_PROMPT", "10"))


settings = Settings()
