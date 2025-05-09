WITH files AS (
    SELECT
        "path",
        LOWER(REGEXP_SUBSTR("path", '\\.[^./]+$'))                           AS ext,
        LENGTH("path") - LENGTH(REPLACE("path", '/', ''))                   AS slash_count
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"
),
filtered AS (
    SELECT
        CASE ext
            WHEN '.py'    THEN 'Python (.py)'
            WHEN '.c'     THEN 'C (.c)'
            WHEN '.ipynb' THEN 'Jupyter Notebook (.ipynb)'
            WHEN '.java'  THEN 'Java (.java)'
            WHEN '.js'    THEN 'JavaScript (.js)'
        END AS file_type
    FROM files
    WHERE slash_count > 10
      AND ext IN ('.py', '.c', '.ipynb', '.java', '.js')
)
SELECT
    file_type,
    COUNT(*) AS file_count
FROM filtered
GROUP BY file_type
ORDER BY file_count DESC NULLS LAST
LIMIT 1;