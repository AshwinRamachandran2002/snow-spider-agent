WITH
-- earliest visit to /regist/input per session
"input" AS (
    SELECT
        "session",
        MIN(TO_TIMESTAMP("stamp")) AS "first_input_time"
    FROM LOG.LOG.FORM_LOG
    WHERE "path" = '/regist/input'
      AND "stamp" <> ''
    GROUP BY "session"
),
-- earliest visit to /regist/confirm per session
"confirm" AS (
    SELECT
        "session",
        MIN(TO_TIMESTAMP("stamp")) AS "first_confirm_time"
    FROM LOG.LOG.FORM_LOG
    WHERE "path" = '/regist/confirm'
      AND "stamp" <> ''
    GROUP BY "session"
),
-- sessions where input occurred before confirm
"ordered_sessions" AS (
    SELECT
        i."session"
    FROM "input" i
    JOIN "confirm" c
      ON i."session" = c."session"
    WHERE i."first_input_time" < c."first_confirm_time"
)
-- count of such unique sessions
SELECT
    COUNT(DISTINCT "session") AS "unique_sessions"
FROM "ordered_sessions";