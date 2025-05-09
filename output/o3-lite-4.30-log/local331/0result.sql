WITH ordered AS (
  SELECT
    "session",
    "stamp",
    "path",
    LAG("path", 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev1,
    LAG("path", 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev2
  FROM "activity_log"
  WHERE "path" IS NOT NULL
),
third_after_two AS (
  SELECT
    "path" AS third_page_path
  FROM ordered
  WHERE prev1 = '/detail'
    AND prev2 = '/detail'
)
SELECT
  third_page_path,
  COUNT(*) AS visit_count
FROM third_after_two
GROUP BY third_page_path
ORDER BY visit_count DESC, third_page_path
LIMIT 3;