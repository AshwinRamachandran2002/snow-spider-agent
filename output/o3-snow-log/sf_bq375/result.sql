WITH filtered AS (
    SELECT
        LOWER(REGEXP_SUBSTR("path", '\\.[^./]+$')) AS file_type
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
    WHERE REGEXP_COUNT("path", '/') > 10
      AND LOWER(REGEXP_SUBSTR("path", '\\.[^./]+$')) IN ('.py', '.c', '.ipynb', '.java', '.js')
)
SELECT
    file_type,
    COUNT(*) AS file_count
FROM filtered
GROUP BY file_type
ORDER BY file_count DESC NULLS LAST
LIMIT 1;