WITH "INPUT_TIMES" AS (
    SELECT 
        "session",
        MIN(TO_TIMESTAMP("stamp")) AS "input_time"
    FROM LOG.LOG.FORM_LOG
    WHERE "path" = '/regist/input'
    GROUP BY "session"
), 
"CONFIRM_TIMES" AS (
    SELECT 
        "session",
        MIN(TO_TIMESTAMP("stamp")) AS "confirm_time"
    FROM LOG.LOG.FORM_LOG
    WHERE "path" = '/regist/confirm'
    GROUP BY "session"
)
SELECT 
    COUNT(DISTINCT i."session") AS "unique_session_count"
FROM "INPUT_TIMES" i
JOIN "CONFIRM_TIMES" c
  ON i."session" = c."session"
WHERE c."confirm_time" > i."input_time";