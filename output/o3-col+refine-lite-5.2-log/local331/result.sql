SELECT
    third_path,
    COUNT(*) AS freq
FROM (
    SELECT
        "session",
        "path" AS third_path
    FROM (
        SELECT
            "session",
            "stamp",
            "path",
            LAG("path", 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev1_path,
            LAG("path", 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev2_path
        FROM activity_log
        WHERE "action" = 'view'
    )
    WHERE prev1_path LIKE '%/detail%' 
      AND prev2_path LIKE '%/detail%'
)
GROUP BY third_path
ORDER BY freq DESC, third_path
LIMIT 3;