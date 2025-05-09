SELECT 
  file_ext,
  COUNT(*) AS file_count
FROM (
  SELECT
    CASE
      WHEN "path" ILIKE '%.py'   THEN '.py'
      WHEN "path" ILIKE '%.c'    THEN '.c'
      WHEN "path" ILIKE '%.ipynb' THEN '.ipynb'
      WHEN "path" ILIKE '%.java' THEN '.java'
      WHEN "path" ILIKE '%.js'   THEN '.js'
    END AS file_ext
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"
  WHERE REGEXP_COUNT("path", '/') > 10
    AND (
         "path" ILIKE '%.py'   OR 
         "path" ILIKE '%.c'    OR 
         "path" ILIKE '%.ipynb' OR 
         "path" ILIKE '%.java' OR 
         "path" ILIKE '%.js'
        )
)
GROUP BY file_ext
ORDER BY file_count DESC NULLS LAST
LIMIT 1;