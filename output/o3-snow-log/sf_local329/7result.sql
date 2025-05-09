WITH filtered AS (
    SELECT
        "session",
        TRY_TO_TIMESTAMP("stamp")       AS "ts",
        "path"
    FROM LOG.LOG.FORM_LOG
    WHERE "path" IN ('/regist/input', '/regist/confirm')
      AND "stamp" <> ''
),
per_session AS (
    SELECT
        "session",
        MIN(CASE WHEN "path" = '/regist/input'   THEN "ts" END) AS first_input_ts,
        MIN(CASE WHEN "path" = '/regist/confirm' THEN "ts" END) AS first_confirm_ts
    FROM filtered
    GROUP BY "session"
)
SELECT COUNT(DISTINCT "session") AS unique_session_cnt
FROM per_session
WHERE first_input_ts IS NOT NULL
  AND first_confirm_ts IS NOT NULL
  AND first_input_ts < first_confirm_ts;