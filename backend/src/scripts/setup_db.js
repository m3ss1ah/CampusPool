const db = require('../config/db');

const migrations = `
DROP TABLE IF EXISTS destination_aliases CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS ride_requests CASCADE;
DROP TABLE IF EXISTS commutes CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 001_create_extensions.sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 002_create_users.sql
CREATE TABLE IF NOT EXISTS users (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name             VARCHAR(100) NOT NULL,
  email                 VARCHAR(255) UNIQUE NOT NULL,
  password_hash         VARCHAR(255) NOT NULL,
  phone                 VARCHAR(20),
  college               VARCHAR(150),
  profile_pic_url       TEXT,                 -- Cloudinary URL
  fcm_token             TEXT,                 -- Firebase device token for push
  has_vehicle           BOOLEAN DEFAULT false,
  vehicle_type          VARCHAR(50),          -- 'bike' | 'car' | 'auto'
  total_rides_offered   INT DEFAULT 0,
  total_rides_joined    INT DEFAULT 0,
  is_active             BOOLEAN DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- 003_create_commutes.sql
CREATE TABLE IF NOT EXISTS commutes (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  creator_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source_label          VARCHAR(200) NOT NULL,
  source_location       GEOGRAPHY(POINT, 4326) NOT NULL,
  source_lat            FLOAT GENERATED ALWAYS AS (ST_Y(source_location::geometry)) STORED,
  source_lng            FLOAT GENERATED ALWAYS AS (ST_X(source_location::geometry)) STORED,
  dest_label            VARCHAR(200) NOT NULL,
  dest_label_normalized VARCHAR(200),         
  dest_location         GEOGRAPHY(POINT, 4326) NOT NULL,
  dest_lat              FLOAT GENERATED ALWAYS AS (ST_Y(dest_location::geometry)) STORED,
  dest_lng              FLOAT GENERATED ALWAYS AS (ST_X(dest_location::geometry)) STORED,
  departure_time        TIMESTAMPTZ NOT NULL,
  total_seats           INT NOT NULL DEFAULT 1 CHECK (total_seats BETWEEN 1 AND 8),
  available_seats       INT NOT NULL DEFAULT 1,
  vehicle_type          VARCHAR(50),
  notes                 TEXT,
  status                VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open','full','ongoing','completed','cancelled')),
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_commutes_source_geo  ON commutes USING GIST(source_location);
CREATE INDEX IF NOT EXISTS idx_commutes_dest_geo    ON commutes USING GIST(dest_location);
CREATE INDEX IF NOT EXISTS idx_commutes_departure   ON commutes(departure_time);
CREATE INDEX IF NOT EXISTS idx_commutes_status      ON commutes(status);
CREATE INDEX IF NOT EXISTS idx_commutes_creator     ON commutes(creator_id);
CREATE INDEX IF NOT EXISTS idx_commutes_dest_normalized_trgm ON commutes USING GIN(dest_label_normalized gin_trgm_ops);

-- 004_create_requests.sql
CREATE TABLE IF NOT EXISTS ride_requests (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  commute_id    UUID NOT NULL REFERENCES commutes(id) ON DELETE CASCADE,
  requester_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status        VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected','cancelled')),
  message       TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(commute_id, requester_id)
);

CREATE INDEX IF NOT EXISTS idx_requests_commute   ON ride_requests(commute_id);
CREATE INDEX IF NOT EXISTS idx_requests_requester ON ride_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_requests_status    ON ride_requests(status);

-- 005_create_conversations.sql
CREATE TABLE IF NOT EXISTS conversations (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  commute_id      UUID REFERENCES commutes(id) ON DELETE SET NULL,
  participant_a   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  participant_b   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  last_message    TEXT,
  last_message_at TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(participant_a, participant_b, commute_id)
);

CREATE INDEX IF NOT EXISTS idx_conversations_a ON conversations(participant_a);
CREATE INDEX IF NOT EXISTS idx_conversations_b ON conversations(participant_b);

-- 006_create_messages.sql
CREATE TABLE IF NOT EXISTS messages (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id   UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content           TEXT NOT NULL,
  is_read           BOOLEAN DEFAULT false,
  deleted_at        TIMESTAMPTZ DEFAULT NULL,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender       ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_active       ON messages(conversation_id, created_at DESC) WHERE deleted_at IS NULL;

-- 007_create_notifications.sql
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type        VARCHAR(50) NOT NULL,
  title       VARCHAR(200) NOT NULL,
  body        TEXT,
  metadata    JSONB,                          
  is_read     BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read, created_at DESC);

-- 008_create_destination_aliases.sql
CREATE TABLE IF NOT EXISTS destination_aliases (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  alias         VARCHAR(200) NOT NULL UNIQUE,   
  canonical     VARCHAR(200) NOT NULL,           
  city          VARCHAR(100),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dest_alias_alias     ON destination_aliases(alias);
CREATE INDEX IF NOT EXISTS idx_dest_alias_canonical ON destination_aliases(canonical);

INSERT INTO destination_aliases (alias, canonical, city) VALUES
  ('bkc', 'bandra_kurla_complex', 'mumbai'),
  ('bandra kurla complex', 'bandra_kurla_complex', 'mumbai'),
  ('bandra kurla', 'bandra_kurla_complex', 'mumbai'),
  ('lower parel', 'lower_parel', 'mumbai'),
  ('lo parel', 'lower_parel', 'mumbai'),
  ('andheri east', 'andheri_east', 'mumbai'),
  ('andheri west', 'andheri_west', 'mumbai'),
  ('andheri station', 'andheri_east', 'mumbai'),
  ('churchgate', 'churchgate', 'mumbai'),
  ('cst', 'csmt', 'mumbai'),
  ('csmt', 'csmt', 'mumbai'),
  ('dadar', 'dadar', 'mumbai'),
  ('thane station', 'thane', 'mumbai'),
  ('powai', 'powai', 'mumbai'),
  ('hiranandani', 'powai', 'mumbai'),
  ('vikhroli', 'vikhroli', 'mumbai'),
  ('ghatkopar', 'ghatkopar', 'mumbai'),
  ('kurla', 'kurla', 'mumbai'),
  ('worli', 'worli', 'mumbai'),
  ('nariman point', 'nariman_point', 'mumbai')
ON CONFLICT (alias) DO NOTHING;
`;

const setup = async () => {
  try {
    console.log('Connecting and running migrations...');
    await db.query(migrations);
    console.log('Migrations completed successfully!');
  } catch (error) {
    console.error('Error running migrations:', error);
  } finally {
    await db.closeDB();
  }
};

setup();
