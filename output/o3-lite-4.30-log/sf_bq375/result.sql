WITH depth_files AS (
    SELECT
        CASE
            WHEN LOWER("path") LIKE '%.py'    THEN '.py'
            WHEN LOWER("path") LIKE '%.c'     THEN '.c'
            WHEN LOWER("path") LIKE '%.ipynb' THEN '.ipynb'
            WHEN LOWER("path") LIKE '%.java'  THEN '.java'
            WHEN LOWER("path") LIKE '%.js'    THEN '.js'
        END AS file_type
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
    WHERE REGEXP_COUNT("path", '/') > 10
)
SELECT
    file_type,
    COUNT(*) AS file_count
FROM depth_files
WHERE file_type IS NOT NULL
GROUP BY file_type
ORDER BY file_count DESC NULLS LAST, file_type
LIMIT 1;