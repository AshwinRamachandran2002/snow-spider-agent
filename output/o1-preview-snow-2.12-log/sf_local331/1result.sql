SELECT
  LOWER(TRIM("third_page", '/')) AS "Third_Page",
  COUNT(*) AS "Count"
FROM (
  SELECT
    "session",
    "stamp",
    LAG(LOWER(TRIM("path", '/')), 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS "first_page",
    LAG(LOWER(TRIM("path", '/')), 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS "second_page",
    "path" AS "third_page"
  FROM
    LOG.LOG.ACTIVITY_LOG
) sub
WHERE
  "first_page" = 'detail' AND
  "second_page" = 'detail'
GROUP BY
  LOWER(TRIM("third_page", '/'))
ORDER BY
  "Count" DESC NULLS LAST
LIMIT 3;