WITH input_time AS (
  SELECT
    session,
    MIN(stamp) AS input_stamp
  FROM form_log
  WHERE path = '/regist/input'
  GROUP BY session
),
confirm_time AS (
  SELECT
    session,
    MIN(stamp) AS confirm_stamp
  FROM form_log
  WHERE path = '/regist/confirm'
  GROUP BY session
)
SELECT COUNT(*) AS num_sessions
FROM input_time
JOIN confirm_time USING (session)
WHERE confirm_time.confirm_stamp > input_time.input_stamp;