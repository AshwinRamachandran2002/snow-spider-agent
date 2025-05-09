WITH input AS (
    SELECT session,
           MIN(stamp) AS input_time
    FROM form_log
    WHERE path = '/regist/input'
    GROUP BY session
),
confirm AS (
    SELECT session,
           MIN(stamp) AS confirm_time
    FROM form_log
    WHERE path = '/regist/confirm'
    GROUP BY session
)
SELECT COUNT(*) AS unique_sessions
FROM input  i
JOIN confirm c
  ON i.session = c.session
WHERE i.input_time < c.confirm_time;