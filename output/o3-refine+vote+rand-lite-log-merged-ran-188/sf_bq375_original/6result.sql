WITH filtered AS (
    SELECT
        "path",
        CASE
            WHEN "path" ILIKE '%.py'    THEN '.py'
            WHEN "path" ILIKE '%.c'     THEN '.c'
            WHEN "path" ILIKE '%.ipynb' THEN '.ipynb'
            WHEN "path" ILIKE '%.java'  THEN '.java'
            WHEN "path" ILIKE '%.js'    THEN '.js'
        END AS file_type
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
    WHERE "path" ILIKE '%.py'
       OR "path" ILIKE '%.c'
       OR "path" ILIKE '%.ipynb'
       OR "path" ILIKE '%.java'
       OR "path" ILIKE '%.js'
),
deep_files AS (
    /* directory depth = number of "/" + 1, need depth > 10  (=> "/" count > 9) */
    SELECT file_type
    FROM filtered
    WHERE REGEXP_COUNT("path", '/') + 1 > 10
)
SELECT
    file_type,
    COUNT(*) AS file_count
FROM deep_files
GROUP BY file_type
ORDER BY file_count DESC NULLS LAST
LIMIT 1;