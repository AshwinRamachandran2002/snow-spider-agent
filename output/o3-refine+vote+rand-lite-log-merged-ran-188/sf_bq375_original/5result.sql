WITH files AS (
    SELECT
        "path",
        -- count how many “/” characters are in the path
        (LENGTH("path") - LENGTH(REPLACE("path", '/', '')))    AS dir_depth,
        -- extract file extension (kept in lower‑case, including the dot)
        LOWER(REGEXP_SUBSTR("path", '\\.[^./]+$'))             AS extension
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
),
filtered AS (
    SELECT
        extension,
        COUNT(*) AS file_count
    FROM files
    WHERE dir_depth > 10                          -- deeper than 10 directories
      AND extension IN ('.py', '.c', '.ipynb', '.java', '.js')
    GROUP BY extension
)
SELECT
    extension,
    file_count
FROM filtered
ORDER BY file_count DESC NULLS LAST
LIMIT 1;