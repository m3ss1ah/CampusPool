-- migrations/003_create_requests_table.sql
CREATE TABLE IF NOT EXISTS ride_requests (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  commute_id    UUID NOT NULL REFERENCES commutes(id) ON DELETE CASCADE,
  requester_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status        VARCHAR(20) DEFAULT 'pending'
                CHECK (status IN ('pending','accepted','rejected','cancelled')),
  message       TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(commute_id, requester_id)
);

CREATE INDEX IF NOT EXISTS idx_requests_commute   ON ride_requests(commute_id);
CREATE INDEX IF NOT EXISTS idx_requests_requester ON ride_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_requests_status    ON ride_requests(status);
