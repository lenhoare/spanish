-- Whether a user's email can be trusted as proof of who they are (for ADMIN_EMAILS and
-- COMPLIMENTARY_EMAILS). Always true for Google. For Microsoft, only when Microsoft confirms the
-- organisation owns the email's domain, or the organisation is in MICROSOFT_TRUSTED_TENANTS.
ALTER TABLE users ADD COLUMN email_trusted INTEGER NOT NULL DEFAULT 0;
UPDATE users SET email_trusted = 1 WHERE provider = 'google';
