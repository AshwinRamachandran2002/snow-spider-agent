WITH seq AS (
    SELECT
        "session",
        "path"                                                         AS first_path,
        LEAD("path",1) OVER (PARTITION BY "session" ORDER BY "stamp")  AS second_path,
        LEAD("path",2) OVER (PARTITION BY "session" ORDER BY "stamp")  AS third_path
    FROM "activity_log"
    WHERE "action" = 'view'
)
SELECT
    third_path  AS third_page_path,
    COUNT(*)    AS visit_count
FROM seq
WHERE first_path  LIKE '/detail%'
  AND second_path LIKE '/detail%'
  AND third_path IS NOT NULL
GROUP BY third_page_path
ORDER BY visit_count DESC,
         third_page_path
LIMIT 3;