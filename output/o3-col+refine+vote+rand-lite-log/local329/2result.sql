SELECT COUNT(*) AS sessions_input_then_confirm
FROM (
    SELECT  "session",
            MIN(CASE WHEN "path" = '/regist/input'   THEN "stamp" END) AS input_time,
            MIN(CASE WHEN "path" = '/regist/confirm' THEN "stamp" END) AS confirm_time
    FROM    "form_log"
    WHERE   "path" IN ('/regist/input', '/regist/confirm')
    GROUP BY "session"
    HAVING  input_time IS NOT NULL
       AND  confirm_time IS NOT NULL
       AND  input_time < confirm_time           -- ensures correct order
) AS ordered_sessions;