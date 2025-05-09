SELECT
  "third_page_path"      AS "third_page_after_two_detail",
  COUNT(*)               AS "times_observed"
FROM (
  SELECT
    "session",
    "path" AS "third_page_path",
    LAG("path", 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS "prev1",
    LAG("path", 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS "prev2"
  FROM "activity_log"
) AS seq
WHERE "prev1" LIKE '/detail%'   -- second page
  AND "prev2" LIKE '/detail%'   -- first page
GROUP BY "third_page_path"
ORDER BY "times_observed" DESC
LIMIT 3;