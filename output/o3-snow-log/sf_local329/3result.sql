WITH events AS (
    SELECT
        "session",
        "path",
        TRY_TO_TIMESTAMP("stamp") AS ts
    FROM LOG.LOG.FORM_LOG
    WHERE "path" IN ('/regist/input', '/regist/confirm')
      AND "session" IS NOT NULL
      AND COALESCE("stamp",'') <> ''
), per_session AS (
    SELECT
        "session",
        MIN(CASE WHEN "path" = '/regist/input'   THEN ts END) AS first_input_ts,
        MIN(CASE WHEN "path" = '/regist/confirm' THEN ts END) AS first_confirm_ts
    FROM events
    GROUP BY "session"
)
SELECT COUNT(*) AS "unique_sessions"
FROM per_session
WHERE first_input_ts IS NOT NULL
  AND first_confirm_ts IS NOT NULL
  AND first_confirm_ts > first_input_ts;