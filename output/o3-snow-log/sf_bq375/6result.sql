WITH files AS (
    SELECT
        LOWER("path") AS path
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
), classified AS (
    SELECT
        CASE
            WHEN path LIKE '%.py'    THEN 'Python (.py)'
            WHEN path LIKE '%.c'     THEN 'C (.c)'
            WHEN path LIKE '%.ipynb' THEN 'Jupyter Notebook (.ipynb)'
            WHEN path LIKE '%.java'  THEN 'Java (.java)'
            WHEN path LIKE '%.js'    THEN 'JavaScript (.js)'
        END                                   AS file_type,
        (LENGTH(path) - LENGTH(REPLACE(path, '/', ''))) AS dir_depth
    FROM files
)
SELECT
    file_type,
    COUNT(*) AS file_count
FROM classified
WHERE file_type IS NOT NULL
  AND dir_depth > 10
GROUP BY file_type
ORDER BY file_count DESC NULLS LAST
LIMIT 1;