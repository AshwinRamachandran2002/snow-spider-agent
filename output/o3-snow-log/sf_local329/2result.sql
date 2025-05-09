WITH "filtered_logs" AS (
    SELECT
        "session",
        "path",
        TO_TIMESTAMP("stamp") AS "ts"
    FROM LOG.LOG.FORM_LOG
    WHERE "path" IN ('/regist/input', '/regist/confirm')
),
"first_hits" AS (
    SELECT
        "session",
        MIN(CASE WHEN "path" = '/regist/input'   THEN "ts" END) AS "first_input_ts",
        MIN(CASE WHEN "path" = '/regist/confirm' THEN "ts" END) AS "first_confirm_ts"
    FROM "filtered_logs"
    GROUP BY "session"
)
SELECT
    COUNT(*) AS "unique_sessions"
FROM "first_hits"
WHERE "first_input_ts" IS NOT NULL
  AND "first_confirm_ts" IS NOT NULL
  AND "first_input_ts" < "first_confirm_ts";