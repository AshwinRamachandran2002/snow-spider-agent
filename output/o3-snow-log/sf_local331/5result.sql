WITH ordered_logs AS (
    SELECT
        "session",
        "path",
        TO_TIMESTAMP_NTZ("stamp")                                       AS ts,
        LAG("path", 1) OVER (PARTITION BY "session" ORDER BY TO_TIMESTAMP_NTZ("stamp")) AS prev_path1,
        LAG("path", 2) OVER (PARTITION BY "session" ORDER BY TO_TIMESTAMP_NTZ("stamp")) AS prev_path2
    FROM LOG.LOG.ACTIVITY_LOG
    WHERE "path" IS NOT NULL
),
third_page AS (
    SELECT
        "path" AS third_path
    FROM ordered_logs
    WHERE prev_path1 ILIKE '/detail%'      -- immediately previous page
      AND prev_path2 ILIKE '/detail%'      -- two steps back
)
SELECT
    third_path,
    COUNT(*) AS visit_count
FROM third_page
GROUP BY third_path
ORDER BY visit_count DESC NULLS LAST
LIMIT 3;