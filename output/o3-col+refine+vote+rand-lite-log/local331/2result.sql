WITH seq AS (
    SELECT
        "session",
        "stamp",
        "path",
        LAG("path", 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev1_path,
        LAG("path", 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev2_path
    FROM activity_log
    WHERE "action" = 'view'
)
SELECT
    "path" AS third_page,
    COUNT(*) AS freq
FROM seq
WHERE prev1_path LIKE '%/detail%' 
  AND prev2_path LIKE '%/detail%'
GROUP BY "path"
ORDER BY freq DESC
LIMIT 3;