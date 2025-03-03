SELECT COUNT(DISTINCT r1."session") AS "Number_of_unique_sessions"
FROM "form_log" r1
JOIN "form_log" r2 ON r1."session" = r2."session"
WHERE r1."path" = '/regist/input'
  AND r2."path" = '/regist/confirm'
  AND r1."stamp" < r2."stamp";