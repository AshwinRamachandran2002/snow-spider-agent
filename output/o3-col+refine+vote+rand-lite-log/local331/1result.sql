WITH ordered AS (
  SELECT
    "session",
    "stamp",
    "path",
    LEAD("path", 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS next_path,
    LEAD("path", 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS third_path
  FROM "activity_log"
),
triples AS (
  SELECT third_path
  FROM ordered
  WHERE "path"      LIKE '%/detail%'   -- first page
    AND next_path   LIKE '%/detail%'   -- second consecutive page
    AND third_path IS NOT NULL         -- third page exists
)
SELECT
  third_path AS "third_page",
  COUNT(*)   AS "occurrences"
FROM triples
GROUP BY third_path
ORDER BY "occurrences" DESC, "third_page"
LIMIT 3;