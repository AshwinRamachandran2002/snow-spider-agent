WITH ordered AS (
    SELECT
        "session",
        "path",
        "stamp",
        ROW_NUMBER() OVER (PARTITION BY "session" ORDER BY "stamp", "path") AS rn
    FROM activity_log
),
detail_pattern AS (
    /* pick the third page right after two consecutive '/detail/' visits */
    SELECT
        o3."path" AS third_page
    FROM ordered o1
    JOIN ordered o2
      ON o2."session" = o1."session"
     AND o2.rn = o1.rn + 1
    JOIN ordered o3
      ON o3."session" = o1."session"
     AND o3.rn = o1.rn + 2
    WHERE o1."path" = '/detail/'
      AND o2."path" = '/detail/'
)
SELECT
    third_page,
    COUNT(*) AS visit_count
FROM detail_pattern
GROUP BY third_page
ORDER BY visit_count DESC,
         third_page
LIMIT 3;