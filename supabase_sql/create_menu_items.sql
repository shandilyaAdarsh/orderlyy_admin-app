-- SQL migration to create `menu_items` table for Supabase/Postgres
-- Adjust types and foreign keys to match your project (tenant id type).

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.menu_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  name text NOT NULL,
  price numeric NOT NULL DEFAULT 0,
  category text,
  image_url text,
  is_available boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_menu_items_tenant_id ON public.menu_items(tenant_id);

-- Optional: trigger to update updated_at on row update
CREATE OR REPLACE FUNCTION public.trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_timestamp ON public.menu_items;
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON public.menu_items
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();
