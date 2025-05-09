SELECT COUNT(DISTINCT fi."session") AS sessions_with_input_then_confirm
FROM   "form_log" AS fi
WHERE  fi."path" = '/regist/input'
  AND  EXISTS (
        SELECT 1
        FROM   "form_log" AS fc
        WHERE  fc."session" = fi."session"
          AND  fc."path"    = '/regist/confirm'
          AND  fc."stamp"   > fi."stamp"
      );