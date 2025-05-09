WITH session_steps AS (
    SELECT
        "session",
        MIN(CASE WHEN "path" = '/regist/input'   THEN "stamp" END) AS first_input_time,
        MIN(CASE WHEN "path" = '/regist/confirm' THEN "stamp" END) AS first_confirm_time
    FROM "form_log"
    GROUP BY "session"
)
SELECT COUNT(*) AS unique_session_cnt
FROM session_steps
WHERE first_input_time IS NOT NULL
  AND first_confirm_time IS NOT NULL
  AND first_input_time < first_confirm_time;