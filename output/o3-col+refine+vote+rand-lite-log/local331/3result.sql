SELECT
    seq.third_page,
    COUNT(*) AS visit_cnt
FROM (
    SELECT
        "path" AS third_page,
        LAG("path", 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev1,
        LAG("path", 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev2
    FROM "activity_log"
) AS seq
WHERE seq.prev1 LIKE '/detail%'  -- second page in the sequence
  AND seq.prev2 LIKE '/detail%'  -- first  page in the sequence
GROUP BY seq.third_page
ORDER BY visit_cnt DESC
LIMIT 3;