\echo CREATE EXTENSION pg_track_settings
\c postgres;
CREATE EXTENSION IF NOT EXISTS pg_track_settings;
SELECT cron.schedule('0 0 * * 6', 'select pg_track_settings_snapshot()');
