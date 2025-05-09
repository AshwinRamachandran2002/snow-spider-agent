SELECT COUNT(*) AS num_sessions
FROM (
  SELECT "session"
  FROM "form_log"
  WHERE "path" IN ('/regist/input', '/regist/confirm')
  GROUP BY "session"
  HAVING MIN(CASE WHEN "path" = '/regist/input'  THEN "stamp" END) IS NOT NULL
     AND MIN(CASE WHEN "path" = '/regist/confirm' THEN "stamp" END) IS NOT NULL
     AND MIN(CASE WHEN "path" = '/regist/input'  THEN "stamp" END)
         < MIN(CASE WHEN "path" = '/regist/confirm' THEN "stamp" END)
) AS ordered_sessions;