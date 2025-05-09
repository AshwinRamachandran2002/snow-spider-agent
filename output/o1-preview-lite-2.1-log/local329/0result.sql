SELECT COUNT(*) AS "Number_of_unique_sessions"
FROM (
    SELECT "session"
    FROM (
        SELECT "session",
               MIN(CASE WHEN "path" = '/regist/input' THEN "stamp" END) AS input_time,
               MIN(CASE WHEN "path" = '/regist/confirm' THEN "stamp" END) AS confirm_time
        FROM "form_log"
        WHERE "path" IN ('/regist/input', '/regist/confirm')
        GROUP BY "session"
    ) sub
    WHERE input_time IS NOT NULL AND confirm_time IS NOT NULL AND input_time < confirm_time
) AS t;