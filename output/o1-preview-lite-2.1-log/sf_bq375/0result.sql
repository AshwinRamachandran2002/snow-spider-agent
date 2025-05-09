SELECT
  CASE
    WHEN "path" LIKE '%.py' THEN '.py'
    WHEN "path" LIKE '%.c' THEN '.c'
    WHEN "path" LIKE '%.ipynb' THEN '.ipynb'
    WHEN "path" LIKE '%.java' THEN '.java'
    WHEN "path" LIKE '%.js' THEN '.js'
  END AS "File_type",
  COUNT(*) AS "File_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
WHERE
  ("path" LIKE '%.py' OR
   "path" LIKE '%.c' OR
   "path" LIKE '%.ipynb' OR
   "path" LIKE '%.java' OR
   "path" LIKE '%.js') AND
  REGEXP_COUNT("path", '/') > 10
GROUP BY "File_type"
ORDER BY "File_count" DESC NULLS LAST;