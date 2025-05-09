WITH ordered AS (
    SELECT
        "session",
        "path",
        LAG("path", 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev1,
        LAG("path", 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev2
    FROM "activity_log"
    WHERE "action" = 'view'          -- only page‑view records
),
third_pages AS (
    SELECT
        "path" AS third_page
    FROM ordered
    WHERE prev1 LIKE '/detail%'      -- 2nd page is “/detail”
      AND prev2 LIKE '/detail%'      -- 1st page is also “/detail”
)
SELECT
    third_page,
    COUNT(*) AS visit_count
FROM third_pages
GROUP BY third_page
ORDER BY visit_count DESC, third_page
LIMIT 3;