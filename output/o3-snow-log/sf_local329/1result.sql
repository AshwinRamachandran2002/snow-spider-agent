WITH filtered AS (
    SELECT 
        "session",
        "path",
        TO_TIMESTAMP("stamp") AS ts
    FROM LOG.LOG.FORM_LOG
    WHERE "path" IN ('/regist/input', '/regist/confirm')
),
per_session AS (
    SELECT
        "session",
        MIN(CASE WHEN "path" = '/regist/input'   THEN ts END) AS input_ts,
        MIN(CASE WHEN "path" = '/regist/confirm' THEN ts END) AS confirm_ts
    FROM filtered
    GROUP BY "session"
)
SELECT COUNT(*) AS unique_session_cnt
FROM per_session
WHERE input_ts IS NOT NULL
  AND confirm_ts IS NOT NULL
  AND input_ts < confirm_ts;