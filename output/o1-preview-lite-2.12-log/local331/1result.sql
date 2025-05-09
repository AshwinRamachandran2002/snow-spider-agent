SELECT
  al3."path" AS "Third_page_url",
  COUNT(*) AS "Count"
FROM "activity_log" AS al1
JOIN "activity_log" AS al2
  ON al1."session" = al2."session"
  AND al2."stamp" > al1."stamp"
JOIN "activity_log" AS al3
  ON al2."session" = al3."session"
  AND al3."stamp" > al2."stamp"
WHERE
  RTRIM(al1."path", '/') = '/detail'
  AND RTRIM(al2."path", '/') = '/detail'
GROUP BY al3."path"
ORDER BY "Count" DESC
LIMIT 3;