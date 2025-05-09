SELECT
  "File_type",
  COUNT(*) AS "File_count"
FROM (
  SELECT
    CASE
      WHEN "path" ILIKE '%.java' THEN '.java'
      WHEN "path" ILIKE '%.js' THEN '.js'
      WHEN "path" ILIKE '%.c' THEN '.c'
      WHEN "path" ILIKE '%.py' THEN '.py'
      WHEN "path" ILIKE '%.ipynb' THEN '.ipynb'
      ELSE NULL
    END AS "File_type"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
  WHERE (LENGTH("path") - LENGTH(REPLACE("path", '/'))) > 10
    AND (
      "path" ILIKE '%.java' OR
      "path" ILIKE '%.js' OR
      "path" ILIKE '%.c' OR
      "path" ILIKE '%.py' OR
      "path" ILIKE '%.ipynb'
    )
) AS FileTypes
WHERE "File_type" IS NOT NULL
GROUP BY "File_type"
ORDER BY "File_count" DESC NULLS LAST
LIMIT 1;