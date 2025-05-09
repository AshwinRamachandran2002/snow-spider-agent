WITH depth_gt_10 AS (
    SELECT
        CASE
            WHEN LOWER("path") LIKE '%.py'    THEN '.py'
            WHEN LOWER("path") LIKE '%.c'     THEN '.c'
            WHEN LOWER("path") LIKE '%.ipynb' THEN '.ipynb'
            WHEN LOWER("path") LIKE '%.java'  THEN '.java'
            WHEN LOWER("path") LIKE '%.js'    THEN '.js'
        END AS "file_type"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
    WHERE (LENGTH("path") - LENGTH(REPLACE("path", '/', ''))) > 10   -- directory depth > 10
      AND (
           LOWER("path") LIKE '%.py' OR
           LOWER("path") LIKE '%.c' OR
           LOWER("path") LIKE '%.ipynb' OR
           LOWER("path") LIKE '%.java' OR
           LOWER("path") LIKE '%.js'
      )
)
SELECT
    "file_type",
    COUNT(*) AS "file_count"
FROM depth_gt_10
GROUP BY "file_type"
ORDER BY "file_count" DESC NULLS LAST
LIMIT 1;