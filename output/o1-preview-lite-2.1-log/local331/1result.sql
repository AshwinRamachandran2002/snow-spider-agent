WITH normalized_activity AS (
  SELECT
    "session",
    "stamp",
    "action",
    RTRIM("path", '/') AS "path_normalized"
  FROM "activity_log"
),
lagged AS (
  SELECT
    "session",
    "stamp",
    "action",
    "path_normalized",
    LAG("path_normalized", 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS "prev_path1",
    LAG("path_normalized", 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS "prev_path2"
  FROM normalized_activity
)
SELECT
  "path_normalized" AS "Third_Action",
  COUNT(*) AS "Occurrence_Count"
FROM lagged
WHERE "prev_path2" = '/detail' AND "prev_path1" = '/detail'
GROUP BY "path_normalized"
ORDER BY "Occurrence_Count" DESC
LIMIT 3;