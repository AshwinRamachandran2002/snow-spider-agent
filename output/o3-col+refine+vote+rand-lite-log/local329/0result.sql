WITH first_hits AS (
    SELECT
        "session",
        MIN(CASE WHEN "path" = '/regist/input'   THEN "stamp" END) AS input_stamp,
        MIN(CASE WHEN "path" = '/regist/confirm' THEN "stamp" END) AS confirm_stamp
    FROM "form_log"
    WHERE "path" IN ('/regist/input', '/regist/confirm')
    GROUP BY "session"
)
SELECT COUNT(*) AS unique_sessions
FROM first_hits
WHERE input_stamp IS NOT NULL
  AND confirm_stamp IS NOT NULL
  AND input_stamp < confirm_stamp;