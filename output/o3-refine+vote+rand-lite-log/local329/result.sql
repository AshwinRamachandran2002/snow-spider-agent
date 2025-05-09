WITH
    input AS (
        SELECT
            "session",
            MIN("stamp") AS input_stamp
        FROM "form_log"
        WHERE "path" = '/regist/input'
        GROUP BY "session"
    ),
    confirm_log AS (
        SELECT
            "session",
            MIN("stamp") AS confirm_stamp
        FROM "form_log"
        WHERE "path" = '/regist/confirm'
        GROUP BY "session"
    )
SELECT COUNT(*) AS num_sessions
FROM input
JOIN confirm_log USING ("session")
WHERE confirm_log.confirm_stamp > input.input_stamp;