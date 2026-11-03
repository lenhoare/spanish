-- Teachers sign in with Google. Students never have accounts: they use a class code
-- from their teacher, so no student personal data is stored at all.

CREATE TABLE users (
  id                  TEXT PRIMARY KEY,
  provider            TEXT NOT NULL,              -- 'google' (room for 'microsoft' later)
  provider_sub        TEXT NOT NULL,              -- the provider's stable user id
  email               TEXT NOT NULL,
  name                TEXT NOT NULL DEFAULT '',
  stripe_customer_id  TEXT,
  created_at          INTEGER NOT NULL,
  last_login_at       INTEGER NOT NULL,
  UNIQUE (provider, provider_sub)
);
CREATE INDEX users_stripe_customer ON users (stripe_customer_id);

CREATE TABLE sessions (
  id          TEXT PRIMARY KEY,                   -- SHA-256 of the cookie token (the token itself is never stored)
  user_id     TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  created_at  INTEGER NOT NULL,
  expires_at  INTEGER NOT NULL
);
CREATE INDEX sessions_user ON sessions (user_id);

-- One row per teacher, kept in sync from Stripe webhooks.
CREATE TABLE subscriptions (
  user_id                 TEXT PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
  stripe_subscription_id  TEXT NOT NULL,
  status                  TEXT NOT NULL,          -- Stripe's status: active, trialing, past_due, canceled, ...
  current_period_end      INTEGER,
  cancel_at_period_end    INTEGER NOT NULL DEFAULT 0,
  updated_at              INTEGER NOT NULL
);

CREATE TABLE classes (
  id          TEXT PRIMARY KEY,
  teacher_id  TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  join_code   TEXT NOT NULL UNIQUE,
  created_at  INTEGER NOT NULL,
  archived    INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX classes_teacher ON classes (teacher_id);
