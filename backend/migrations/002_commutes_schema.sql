-- migrations/002_commutes_schema.sql

-- 1. Refine Users Table (Align with Master Doc)
ALTER TABLE users ADD COLUMN IF NOT EXISTS full_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS college VARCHAR(150);
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_pic_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_vehicle BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_type VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_rides_offered INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_rides_joined INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Migrate data from first_name/last_name to full_name if they exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='first_name') THEN
        UPDATE users SET full_name = first_name || ' ' || last_name;
        ALTER TABLE users DROP COLUMN first_name;
        ALTER TABLE users DROP COLUMN last_name;
    END IF;
END $$;

-- 2. Create Commutes Table with PostGIS
CREATE TABLE IF NOT EXISTS commutes (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  creator_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Source
  source_label          VARCHAR(200) NOT NULL,
  source_location       GEOGRAPHY(POINT, 4326) NOT NULL,
  -- Generated columns for easy API serialization
  source_lat            FLOAT GENERATED ALWAYS AS (ST_Y(source_location::geometry)) STORED,
  source_lng            FLOAT GENERATED ALWAYS AS (ST_X(source_location::geometry)) STORED,

  -- Destination
  dest_label            VARCHAR(200) NOT NULL,
  dest_location         GEOGRAPHY(POINT, 4326) NOT NULL,
  -- Generated columns
  dest_lat              FLOAT GENERATED ALWAYS AS (ST_Y(dest_location::geometry)) STORED,
  dest_lng              FLOAT GENERATED ALWAYS AS (ST_X(dest_location::geometry)) STORED,

  -- Timing & seats
  departure_time        TIMESTAMPTZ NOT NULL,
  total_seats           INT NOT NULL DEFAULT 1 CHECK (total_seats BETWEEN 1 AND 8),
  available_seats       INT NOT NULL DEFAULT 1,
  vehicle_type          VARCHAR(50),
  notes                 TEXT,
  status                VARCHAR(20) DEFAULT 'open'
                        CHECK (status IN ('open','full','ongoing','completed','cancelled')),
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Spatial Indexes
CREATE INDEX IF NOT EXISTS idx_commutes_source_geo  ON commutes USING GIST(source_location);
CREATE INDEX IF NOT EXISTS idx_commutes_dest_geo    ON commutes USING GIST(dest_location);
CREATE INDEX IF NOT EXISTS idx_commutes_departure   ON commutes(departure_time);
CREATE INDEX IF NOT EXISTS idx_commutes_status      ON commutes(status);
CREATE INDEX IF NOT EXISTS idx_commutes_creator     ON commutes(creator_id);
