WITH "SESSION_STEPS" AS (
    SELECT
        "session",
        MIN(CASE WHEN "path" = '/regist/input'   THEN TO_TIMESTAMP("stamp") END) AS "first_input_time",
        MIN(CASE WHEN "path" = '/regist/confirm' THEN TO_TIMESTAMP("stamp") END) AS "first_confirm_time"
    FROM LOG.LOG.FORM_LOG
    WHERE "path" IN ('/regist/input', '/regist/confirm')
    GROUP BY "session"
)
SELECT COUNT(DISTINCT "session") AS "unique_session_count"
FROM "SESSION_STEPS"
WHERE "first_input_time" IS NOT NULL
  AND "first_confirm_time" IS NOT NULL
  AND "first_confirm_time" > "first_input_time";