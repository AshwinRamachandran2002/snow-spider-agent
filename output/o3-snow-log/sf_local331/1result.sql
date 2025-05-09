WITH ordered AS (
    SELECT
        "session",
        "path",
        ROW_NUMBER() OVER (PARTITION BY "session" ORDER BY "stamp") AS rn
    FROM LOG.LOG.ACTIVITY_LOG
),
lagged AS (
    SELECT
        "session",
        "path"                                     AS third_page,
        LAG("path", 1) OVER (PARTITION BY "session" ORDER BY rn) AS prev1_path,
        LAG("path", 2) OVER (PARTITION BY "session" ORDER BY rn) AS prev2_path
    FROM ordered
)
SELECT
    third_page,
    COUNT(*) AS visit_count
FROM lagged
WHERE prev1_path = '/detail/' 
  AND prev2_path = '/detail/'
GROUP BY third_page
ORDER BY visit_count DESC NULLS LAST
LIMIT 3;