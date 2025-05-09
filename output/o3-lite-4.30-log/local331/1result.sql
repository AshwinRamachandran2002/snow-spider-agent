WITH seq AS (
    SELECT
        session,
        path,
        LAG(path,1) OVER (PARTITION BY session ORDER BY stamp) AS prev1,
        LAG(path,2) OVER (PARTITION BY session ORDER BY stamp) AS prev2
    FROM activity_log
    WHERE action = 'view'
),
third_page AS (
    SELECT
        path AS third_page_path
    FROM seq
    WHERE prev1 LIKE '/detail%'    -- two consecutive visits to "/detail"
      AND prev2 LIKE '/detail%'
      AND path  NOT LIKE '/detail%'-- the third page must be different
)
SELECT
    third_page_path,
    COUNT(*) AS visit_count
FROM third_page
GROUP BY third_page_path
ORDER BY visit_count DESC, third_page_path
LIMIT 3;