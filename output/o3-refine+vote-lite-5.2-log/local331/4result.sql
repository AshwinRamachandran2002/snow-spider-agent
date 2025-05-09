WITH ordered AS (
    SELECT
        "session",
        datetime("stamp") AS stamp_dt,
        "path",
        ROW_NUMBER() OVER (
            PARTITION BY "session"
            ORDER BY datetime("stamp")
        ) AS rn
    FROM "activity_log"
    WHERE "path" IS NOT NULL
),
triples AS (
    SELECT
        o3."path" AS third_page
    FROM ordered o1
    JOIN ordered o2
        ON  o2."session" = o1."session"
        AND o2.rn       = o1.rn + 1
    JOIN ordered o3
        ON  o3."session" = o1."session"
        AND o3.rn       = o1.rn + 2
    WHERE o1."path" LIKE '/detail%'
      AND o2."path" LIKE '/detail%'
)
SELECT
    third_page,
    COUNT(*) AS occurrences
FROM triples
GROUP BY third_page
ORDER BY occurrences DESC,
         third_page
LIMIT 3;