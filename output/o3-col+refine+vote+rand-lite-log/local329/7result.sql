SELECT COUNT(*) AS sessions_input_then_confirm
FROM (
  SELECT session
  FROM (
    SELECT
      session,
      MIN(CASE WHEN path = '/regist/input'   THEN stamp END) AS first_input,
      MIN(CASE WHEN path = '/regist/confirm' THEN stamp END) AS first_confirm
    FROM form_log
    WHERE path IN ('/regist/input', '/regist/confirm')
    GROUP BY session
  ) AS t
  WHERE first_input IS NOT NULL
    AND first_confirm IS NOT NULL
    AND first_input < first_confirm
) AS s;