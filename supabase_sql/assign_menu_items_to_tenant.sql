-- Safe SQL helper to assign or copy menu items into a target tenant
-- Usage: replace <TARGET_TENANT_UUID> and optionally <SOURCE_TENANT_UUID>
-- This script will COPY rows (create new ids) for items matching the WHERE clause.
-- It avoids modifying existing rows.

-- Example: replace the placeholder and run in psql or Supabase SQL editor.

BEGIN;

-- Set these values before running
-- 
-- TARGET_TENANT_UUID: the tenant that should own the copied items
-- SOURCE_TENANT_UUID: optional; if set, copy items from this tenant; otherwise copy global items (tenant_id IS NULL)

-- Replace these placeholders:
--   '00000000-0000-0000-0000-000000000000' -> your target tenant id
--   'SOURCE-OPTIONAL-UUID' -> optional source tenant id or leave as NULL

-- Example (manual edit):
-- WITH params AS (
--   SELECT 'your-target-tenant-uuid'::uuid AS target, NULL::uuid AS source
-- )

WITH params AS (
  SELECT '<TARGET_TENANT_UUID>'::uuid AS target, NULL::uuid AS source
)
INSERT INTO public.menu_items (id, tenant_id, name, price, category, image_url, is_available, sort_order, created_at, updated_at)
SELECT gen_random_uuid(), params.target, mi.name, mi.price, mi.category, mi.image_url, mi.is_available, mi.sort_order, now(), now()
FROM public.menu_items mi, params
WHERE (
  (params.source IS NULL AND mi.tenant_id IS NULL)
  OR (params.source IS NOT NULL AND mi.tenant_id = params.source)
)
-- Optional: avoid copying duplicates by name for the same tenant
AND NOT EXISTS (
  SELECT 1 FROM public.menu_items m2 WHERE m2.tenant_id = params.target AND lower(m2.name) = lower(mi.name)
);

COMMIT;

-- NOTE:
-- - Review the rows inserted and run in a transaction backup environment first.
-- - If your tenant_id column uses text instead of uuid, remove the ::uuid casts.
-- - If you want to MOVE items instead of COPY, use UPDATE ... SET tenant_id = <target> WHERE ...
