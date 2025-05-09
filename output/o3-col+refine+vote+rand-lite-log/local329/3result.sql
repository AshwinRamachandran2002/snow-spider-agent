SELECT COUNT(DISTINCT fl1."session") AS "sessions_input_then_confirm"
FROM "form_log" AS fl1
JOIN "form_log" AS fl2
  ON fl1."session" = fl2."session"
WHERE fl1."path"  = '/regist/input'
  AND fl2."path"  = '/regist/confirm'
  AND fl1."stamp" < fl2."stamp";