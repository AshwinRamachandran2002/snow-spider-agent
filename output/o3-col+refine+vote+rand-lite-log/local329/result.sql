SELECT COUNT(DISTINCT fi."session") AS unique_sessions
FROM "form_log" AS fi
JOIN "form_log" AS fc
  ON fi."session" = fc."session"
WHERE fi."path" = '/regist/input'
  AND fc."path" = '/regist/confirm'
  AND datetime(fi."stamp") < datetime(fc."stamp");