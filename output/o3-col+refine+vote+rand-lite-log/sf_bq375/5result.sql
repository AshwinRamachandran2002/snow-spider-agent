SELECT
  "extension",
  "file_count"
FROM (
  SELECT
    CASE
      WHEN LOWER("path") LIKE '%.py'    THEN '.py'
      WHEN LOWER("path") LIKE '%.c'     THEN '.c'
      WHEN LOWER("path") LIKE '%.ipynb' THEN '.ipynb'
      WHEN LOWER("path") LIKE '%.java'  THEN '.java'
      WHEN LOWER("path") LIKE '%.js'    THEN '.js'
    END                                    AS "extension",
    COUNT(*)                               AS "file_count"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
  WHERE REGEXP_COUNT("path", '\/') > 10
    AND (
         LOWER("path") LIKE '%.py'
      OR LOWER("path") LIKE '%.c'
      OR LOWER("path") LIKE '%.ipynb'
      OR LOWER("path") LIKE '%.java'
      OR LOWER("path") LIKE '%.js'
    )
  GROUP BY "extension"
)
ORDER BY "file_count" DESC NULLS LAST
LIMIT 1;