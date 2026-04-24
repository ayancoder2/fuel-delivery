# Database Migration Guide

This project uses a structured migration system to manage database changes. All migrations are stored in the `supabase/migrations` directory.

## How to Apply the Initial Schema

If you are setting up the database for the first time or want to reset it:

1.  **Open Supabase Dashboard**: Go to your Supabase project.
2.  **SQL Editor**: Open the SQL Editor and create a new query.
3.  **Copy Schema**: Copy the contents of `supabase/migrations/00001_initial_schema.sql`.
4.  **Run**: Execute the query.

> [!CAUTION]
> Running the initial schema on an existing database will fail if tables already exist. You may need to drop existing tables first if you want a clean slate.

## Resetting the Database (DANGER)

If you need to completely clear the database and re-apply the schema, you can use the following snippet before running the migration:

```sql
DO $$ DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
    FOR r IN (SELECT typname FROM pg_type WHERE typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public') AND typtype = 'e') LOOP
        EXECUTE 'DROP TYPE IF EXISTS public.' || quote_ident(r.typname) || ' CASCADE';
    END LOOP;
END $$;
```

## Adding New Changes

When you need to change the database:
1.  Create a new file in `supabase/migrations/` (e.g., `00002_add_new_table.sql`).
2.  Add your SQL changes there.
3.  Run the SQL in the Supabase Dashboard.

## Supabase CLI (Recommended)

If you have the [Supabase CLI](https://supabase.com/docs/guides/cli) installed:

```bash
# To apply local migrations to your remote project
supabase db push
```
