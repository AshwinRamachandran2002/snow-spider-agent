SELECT 
  "file_type",
  COUNT(*) AS "file_count"
FROM (
  SELECT
    CASE
      WHEN LOWER("path") LIKE '%.py'      THEN 'Python (.py)'
      WHEN LOWER("path") LIKE '%.c'       THEN 'C (.c)'
      WHEN LOWER("path") LIKE '%.ipynb'   THEN 'Jupyter Notebook (.ipynb)'
      WHEN LOWER("path") LIKE '%.java'    THEN 'Java (.java)'
      WHEN LOWER("path") LIKE '%.js'      THEN 'JavaScript (.js)'
    END AS "file_type"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
  WHERE (LENGTH("path") - LENGTH(REPLACE("path", '/', ''))) > 10   -- directory depth > 10
) AS sub
WHERE "file_type" IS NOT NULL
GROUP BY "file_type"
ORDER BY "file_count" DESC NULLS LAST
LIMIT 1;