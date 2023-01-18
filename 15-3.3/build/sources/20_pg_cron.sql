\echo CREATE EXTENSION pg_cron;
\c postgres;
CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT cron.schedule('30 3 * * 6', $$DELETE FROM events WHERE event_time < now() - interval '1 year'$$);
