SELECT
  CASE
    WHEN LOWER("path") LIKE '%.py'    THEN 'Python (.py)'
    WHEN LOWER("path") LIKE '%.c'     THEN 'C (.c)'
    WHEN LOWER("path") LIKE '%.ipynb' THEN 'Jupyter Notebook (.ipynb)'
    WHEN LOWER("path") LIKE '%.java'  THEN 'Java (.java)'
    WHEN LOWER("path") LIKE '%.js'    THEN 'JavaScript (.js)'
  END                                                   AS "file_type",
  COUNT(*)                                              AS "file_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
WHERE (
        LOWER("path") LIKE '%.py'    OR
        LOWER("path") LIKE '%.c'     OR
        LOWER("path") LIKE '%.ipynb' OR
        LOWER("path") LIKE '%.java'  OR
        LOWER("path") LIKE '%.js'
      )
  AND (LENGTH("path") - LENGTH(REPLACE("path", '/', ''))) > 10
GROUP BY "file_type"
ORDER BY "file_count" DESC NULLS LAST
LIMIT 1;