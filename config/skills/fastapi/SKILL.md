---
name: fastapi
description: FastAPI backend service patterns with Python 3.12+
---
When working with Python FastAPI services:

## Project Structure
- `uv` as package manager (not pip)
- `pyproject.toml` for dependencies, not requirements.txt
- Pydantic Settings for configuration
- Structlog for structured logging

## Code Style
- Ruff for linting and formatting (not Black/isort separately)
- MyPy for type checking with strict mode
- Line length: 120 characters
- Type hints on all function signatures

## API Patterns
- Pydantic v2 models for request/response schemas
- Dependency injection via `Depends()`
- Async endpoints with `async def` where I/O bound
- HTTPX for async HTTP client calls

## Database
- SQLAlchemy with Alembic migrations
- Async sessions where possible
- Separate migration files per schema change

## Testing
- pytest with asyncio support (`pytest-asyncio`)
- Markers: unit, integration, contract, performance
- pytest-cov for coverage (target: 80%+)

## Deployment
- Docker multi-stage builds with python:3.12-slim
- Non-root user in container
- Uvicorn with SIGINT graceful shutdown
- Health check endpoint at `/health`
