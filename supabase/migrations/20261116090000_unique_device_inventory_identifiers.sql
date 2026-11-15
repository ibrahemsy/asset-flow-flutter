-- Prevent assigning the same physical barcode or inventory asset number
-- to multiple devices. Empty values remain allowed for legacy/incomplete records.
CREATE UNIQUE INDEX IF NOT EXISTS devices_barcode_unique_nonblank_idx
  ON public.devices (lower(btrim(barcode)))
  WHERE NULLIF(btrim(barcode), '') IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS devices_asset_number_unique_nonblank_idx
  ON public.devices (lower(btrim(asset_number)))
  WHERE NULLIF(btrim(asset_number), '') IS NOT NULL;
