# Database Migrations

This project uses Flask-Migrate (Alembic) for database migrations.

## Commands

```bash
# Initialize migrations (first time only)
flask db init

# Create a new migration after model changes
flask db migrate -m "describe your change"

# Apply migrations to the database
flask db upgrade

# Rollback last migration
flask db downgrade
```

## Notes
- The `database/schema.sql` file is provided for direct MySQL import.
- Use Flask-Migrate for incremental changes in development.
- Always backup the database before running migrations in production.
