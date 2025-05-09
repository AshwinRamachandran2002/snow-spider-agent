WITH
    input AS (
        SELECT "session", MIN("stamp") AS input_stamp
        FROM "form_log"
        WHERE "path" = '/regist/input'
        GROUP BY "session"
    ),
    confirm AS (
        SELECT "session", MIN("stamp") AS confirm_stamp
        FROM "form_log"
        WHERE "path" = '/regist/confirm'
        GROUP BY "session"
    )
SELECT COUNT(*) AS sessions_in_correct_order
FROM input
JOIN confirm USING ("session")
WHERE input.input_stamp < confirm.confirm_stamp;