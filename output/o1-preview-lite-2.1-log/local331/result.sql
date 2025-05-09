SELECT "path" AS Third_Action, COUNT(*) AS Occurrence_Count
FROM (
  SELECT "session",
    LAG("path", 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev_path1,
    LAG("path", 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev_path2,
    "path"
  FROM "activity_log"
) AS sub
WHERE prev_path1 IN ('/detail', '/detail/') AND prev_path2 IN ('/detail', '/detail/')
  AND "path" IS NOT NULL AND "path" <> ''
GROUP BY "path"
ORDER BY Occurrence_Count DESC
LIMIT 3;