WITH ordered AS (
    SELECT
        "session",
        "stamp",
        "path",
        ROW_NUMBER() OVER (
            PARTITION BY "session"
            ORDER BY "stamp"
        ) AS rn
    FROM "activity_log"
    WHERE "path" IS NOT NULL
),
third_pages AS (
    SELECT
        o3."path" AS third_page
    FROM ordered o3
    JOIN ordered o2
      ON o2."session" = o3."session"
     AND o2.rn       = o3.rn - 1
    JOIN ordered o1
      ON o1."session" = o3."session"
     AND o1.rn       = o3.rn - 2
    WHERE o1."path" = '/detail'
      AND o2."path" = '/detail'
)
SELECT
    third_page,
    COUNT(*) AS occurrences
FROM third_pages
GROUP BY third_page
ORDER BY occurrences DESC, third_page
LIMIT 3;