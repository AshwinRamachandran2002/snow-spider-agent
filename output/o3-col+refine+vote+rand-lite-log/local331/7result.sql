SELECT
    third_page,
    COUNT(*) AS cnt
FROM (
    -- pick the page that came right after two consecutive '/detail' visits
    SELECT
        path AS third_page
    FROM (
        SELECT
            session,
            stamp,
            path,
            LAG(path, 1) OVER (PARTITION BY session ORDER BY stamp) AS prev1,
            LAG(path, 2) OVER (PARTITION BY session ORDER BY stamp) AS prev2
        FROM activity_log
    )
    WHERE prev1 LIKE '/detail%'      -- immediately previous page is '/detail'
      AND prev2 LIKE '/detail%'      -- page before that is also '/detail'
      AND path IS NOT NULL           -- ignore NULL paths
)
GROUP BY third_page
ORDER BY cnt DESC
LIMIT 3;