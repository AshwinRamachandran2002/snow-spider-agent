SELECT COUNT(DISTINCT f1."session") AS unique_sessions
FROM   "form_log" AS f1
WHERE  f1."path" = '/regist/input'
  AND  EXISTS (
        SELECT 1
        FROM   "form_log" AS f2
        WHERE  f2."session" = f1."session"
          AND  f2."path"    = '/regist/confirm'
          AND  f2."stamp"   > f1."stamp"
      );