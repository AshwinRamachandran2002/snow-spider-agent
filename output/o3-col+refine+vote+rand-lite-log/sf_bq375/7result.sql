WITH deep_files AS (
  SELECT
    CASE
      WHEN "path" ILIKE '%.py'    THEN '.py'
      WHEN "path" ILIKE '%.c'     THEN '.c'
      WHEN "path" ILIKE '%.ipynb' THEN '.ipynb'
      WHEN "path" ILIKE '%.java'  THEN '.java'
      WHEN "path" ILIKE '%.js'    THEN '.js'
    END AS "extension"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
  WHERE REGEXP_COUNT("path", '/') > 10
    AND (
         "path" ILIKE '%.py'    OR
         "path" ILIKE '%.c'     OR
         "path" ILIKE '%.ipynb' OR
         "path" ILIKE '%.java'  OR
         "path" ILIKE '%.js'
        )
)
SELECT
  "extension",
  COUNT(*) AS "file_count"
FROM deep_files
GROUP BY "extension"
ORDER BY "file_count" DESC NULLS LAST
LIMIT 1;