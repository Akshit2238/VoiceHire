-- ══════════════════════════════════════════════════════════════
--  VoiceHire — Booking & QR Verification System
--  Run this in your Supabase SQL Editor (Dashboard → SQL Editor)
-- ══════════════════════════════════════════════════════════════

-- Drop if re-running
DROP TABLE IF EXISTS bookings;

-- ── bookings table ─────────────────────────────────────────────
CREATE TABLE bookings (
  id          BIGINT      PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  customer_id BIGINT      NOT NULL,   -- references users.id
  worker_id   BIGINT      NOT NULL,   -- references workers.id
  date        DATE        NOT NULL,
  time_slot   TEXT        NOT NULL,   -- e.g. "09:00-11:00"
  status      TEXT        NOT NULL DEFAULT 'Booked',
  --   Allowed values: 'Booked' | 'Work Started' | 'Completed' | 'Cancelled'
  qr_token    TEXT        NOT NULL UNIQUE,  -- HMAC-SHA256 signed token
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Prevent double booking: same worker + date + slot ──────────
CREATE UNIQUE INDEX idx_bookings_no_double
  ON bookings (worker_id, date, time_slot)
  WHERE status <> 'Cancelled';

-- ── Helpful indexes ────────────────────────────────────────────
CREATE INDEX idx_bookings_customer  ON bookings (customer_id);
CREATE INDEX idx_bookings_worker    ON bookings (worker_id);
CREATE INDEX idx_bookings_date      ON bookings (date);
CREATE INDEX idx_bookings_status    ON bookings (status);

-- ── Auto-update updated_at on every row change ─────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_bookings_updated_at
  BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ── Row-Level Security (recommended for Supabase) ──────────────
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Allow service role (your Python backend) full access:
CREATE POLICY "service_role_full_access"
  ON bookings
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- ══════════════════════════════════════════════════════════════
--  Verify: expected columns
-- ══════════════════════════════════════════════════════════════
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_name = 'bookings' ORDER BY ordinal_position;
