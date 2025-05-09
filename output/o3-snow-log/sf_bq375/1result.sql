WITH file_stats AS (
    SELECT
        LOWER(SPLIT_PART("path", '.', -1))                              AS "ext",
        (LENGTH("path") - LENGTH(REPLACE("path", '/', '')))            AS "depth"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
)
SELECT
    "ext",
    COUNT(*) AS "file_count"
FROM file_stats
WHERE "ext" IN ('py','c','ipynb','java','js')
  AND "depth" > 10
GROUP BY "ext"
ORDER BY "file_count" DESC NULLS LAST
LIMIT 1;