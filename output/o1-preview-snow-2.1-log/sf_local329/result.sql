WITH input_times AS (
  SELECT "session", MIN(TO_TIMESTAMP("stamp")) AS first_input_time
  FROM LOG.LOG.FORM_LOG
  WHERE "path" = '/regist/input'
  GROUP BY "session"
),
confirm_times AS (
  SELECT "session", MIN(TO_TIMESTAMP("stamp")) AS first_confirm_time
  FROM LOG.LOG.FORM_LOG
  WHERE "path" = '/regist/confirm'
  GROUP BY "session"
)
SELECT COUNT(*) AS "number_of_unique_sessions"
FROM input_times
JOIN confirm_times USING ("session")
WHERE input_times.first_input_time < confirm_times.first_confirm_time;