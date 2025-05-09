WITH seq AS (
    SELECT
        path                                          AS third_page
    FROM (
        SELECT
            session,
            path,
            LAG(path, 1) OVER (PARTITION BY session ORDER BY stamp) AS prev1,
            LAG(path, 2) OVER (PARTITION BY session ORDER BY stamp) AS prev2
        FROM activity_log
    ) t
    WHERE prev2 LIKE '/detail%'            -- two consecutive '/detail' visits
      AND prev1 LIKE '/detail%'
)
SELECT
    third_page,
    COUNT(*) AS visits
FROM seq
GROUP BY third_page
ORDER BY visits DESC, third_page
LIMIT 3;