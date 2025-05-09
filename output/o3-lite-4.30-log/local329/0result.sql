SELECT COUNT(DISTINCT i."session") AS unique_sessions
FROM   "form_log" AS i
JOIN   "form_log" AS c
       ON  i."session" = c."session"
       AND i."stamp"   < c."stamp"
WHERE  i."path" = '/regist/input'
  AND  c."path" = '/regist/confirm';