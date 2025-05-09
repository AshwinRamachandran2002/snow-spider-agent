WITH "FILTERED" AS (
    SELECT
        CASE
            WHEN LOWER("path") LIKE '%.py'     THEN '.py'
            WHEN LOWER("path") LIKE '%.c'      THEN '.c'
            WHEN LOWER("path") LIKE '%.ipynb'  THEN '.ipynb'
            WHEN LOWER("path") LIKE '%.java'   THEN '.java'
            WHEN LOWER("path") LIKE '%.js'     THEN '.js'
        END AS "file_type"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
    WHERE (
            LOWER("path") LIKE '%.py'    OR
            LOWER("path") LIKE '%.c'     OR
            LOWER("path") LIKE '%.ipynb' OR
            LOWER("path") LIKE '%.java'  OR
            LOWER("path") LIKE '%.js'
          )
      AND REGEXP_COUNT("path", '/') > 10
)
SELECT "file_type",
       COUNT(*) AS "file_count"
FROM "FILTERED"
GROUP BY "file_type"
ORDER BY "file_count" DESC NULLS LAST
LIMIT 1;