SELECT
    file_type,
    deep_file_cnt AS file_count
FROM (
    SELECT
        CASE
            WHEN LOWER("path") LIKE '%.py'    THEN 'python'
            WHEN LOWER("path") LIKE '%.c'     THEN 'c'
            WHEN LOWER("path") LIKE '%.ipynb' THEN 'notebook'
            WHEN LOWER("path") LIKE '%.java'  THEN 'java'
            WHEN LOWER("path") LIKE '%.js'    THEN 'javascript'
        END AS file_type,
        COUNT(*) AS deep_file_cnt
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
    WHERE (LENGTH("path") - LENGTH(REPLACE("path", '/', ''))) + 1 > 10
      AND (
            LOWER("path") LIKE '%.py'    OR
            LOWER("path") LIKE '%.c'     OR
            LOWER("path") LIKE '%.ipynb' OR
            LOWER("path") LIKE '%.java'  OR
            LOWER("path") LIKE '%.js'
          )
    GROUP BY file_type
)
ORDER BY deep_file_cnt DESC NULLS LAST
LIMIT 1;