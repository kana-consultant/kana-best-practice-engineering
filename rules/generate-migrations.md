---
name: generate-migrations
description: Enforce auto-generated migrations only — no hand-written migration files
---

# Generate Migrations Rule

All database migrations MUST be auto-generated. Never write migration files by hand.

## Rule

Use the ORM/migration tool's generation command to produce migration files from schema changes. The developer's job is to modify the schema — the tool creates the migration.

## Workflow

1. Edit the schema definition (e.g., Drizzle schema, Prisma schema, Alembic model).
2. Run the migration generation command.
3. Review the generated migration for correctness.
4. Commit the migration file alongside the schema change.

## Examples by tool

| Tool | Generate command |
|------|-----------------|
| Drizzle | `pnpm drizzle-kit generate` |
| Prisma | `pnpm prisma migrate dev --name <name>` |
| Alembic | `alembic revision --autogenerate -m "<name>"` |
| TypeORM | `pnpm typeorm migration:generate -n <name>` |

## Non-negotiables

1. NEVER create a migration file manually (e.g., writing SQL or TypeScript migration code by hand).
2. NEVER edit a generated migration file after generation — if it's wrong, fix the schema and regenerate.
3. ALWAYS let the ORM/tool diff the schema and produce the migration.
4. If the auto-generated migration is incomplete or incorrect, adjust the schema definition and regenerate — do not patch the migration file directly.
5. Migration files are artifacts of the schema, not source-of-truth. The schema is the source-of-truth.
