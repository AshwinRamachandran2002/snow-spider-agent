SELECT
  third_page,
  COUNT(*) AS cnt
FROM (
  SELECT
    "session",
    "stamp",
    "path" AS third_page,
    LAG("path",1) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev1,
    LAG("path",2) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev2
  FROM "activity_log"
) sub
WHERE prev1 LIKE '%/detail%'      -- immediately after a detail page
  AND prev2 LIKE '%/detail%'      -- and the page before that also a detail page
GROUP BY third_page
ORDER BY cnt DESC
LIMIT 3;