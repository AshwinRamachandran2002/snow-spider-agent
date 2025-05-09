WITH seq AS (
  SELECT
    "session",
    "path",
    LEAD("path", 1) OVER (PARTITION BY "session" ORDER BY "stamp")  AS next_path,
    LEAD("path", 2) OVER (PARTITION BY "session" ORDER BY "stamp")  AS third_path
  FROM "activity_log"
)
SELECT
  third_path AS third_page,
  COUNT(*)   AS visits
FROM seq
WHERE "path"      LIKE '/detail%'
  AND next_path   LIKE '/detail%'
  AND third_path IS NOT NULL
GROUP BY third_path
ORDER BY visits DESC, third_page
LIMIT 3;