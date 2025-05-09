WITH ordered AS (
    SELECT
        "session",
        TO_TIMESTAMP_NTZ("stamp")                               AS ts,
        "path"
    FROM LOG.LOG.ACTIVITY_LOG
    WHERE "path" IS NOT NULL
), seq AS (
    SELECT
        "session",
        "path"                                                       AS first_path,
        LEAD("path", 1)  OVER (PARTITION BY "session" ORDER BY ts)   AS second_path,
        LEAD("path", 2)  OVER (PARTITION BY "session" ORDER BY ts)   AS third_path
    FROM ordered
)
SELECT
    third_path      AS "third_page",
    COUNT(*)        AS "visit_count"
FROM seq
WHERE first_path  ILIKE '/detail%'     -- 1st '/detail' page
  AND second_path ILIKE '/detail%'     -- 2nd consecutive '/detail' page
  AND third_path IS NOT NULL           -- page that follows the two '/detail' pages
GROUP BY third_path
ORDER BY "visit_count" DESC NULLS LAST
LIMIT 3;