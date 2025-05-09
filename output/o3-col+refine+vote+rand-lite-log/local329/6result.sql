WITH first_input AS (
  SELECT "session",
         MIN("stamp") AS input_time
  FROM   "form_log"
  WHERE  "action" = 'view'
    AND  "path"   = '/regist/input'
  GROUP BY "session"
),
first_confirm AS (
  SELECT "session",
         MIN("stamp") AS confirm_time
  FROM   "form_log"
  WHERE  "action" = 'view'
    AND  "path"   = '/regist/confirm'
  GROUP BY "session"
)
SELECT COUNT(*) AS unique_sessions
FROM   first_input
JOIN   first_confirm USING ("session")
WHERE  input_time < confirm_time;