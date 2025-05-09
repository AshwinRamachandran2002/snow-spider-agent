WITH filtered_log AS (
    SELECT
        "session",
        "path",
        TRY_TO_TIMESTAMP("stamp") AS ts
    FROM LOG.LOG.FORM_LOG
    WHERE "path" IN ('/regist/input', '/regist/confirm')
), 
session_steps AS (
    SELECT
        "session",
        MIN(CASE WHEN "path" = '/regist/input'   THEN ts END) AS first_input_time,
        MIN(CASE WHEN "path" = '/regist/confirm' THEN ts END) AS first_confirm_time
    FROM filtered_log
    GROUP BY "session"
)
SELECT COUNT(DISTINCT "session") AS "UNIQUE_SESSIONS"
FROM session_steps
WHERE first_input_time IS NOT NULL
  AND first_confirm_time IS NOT NULL
  AND first_input_time < first_confirm_time;