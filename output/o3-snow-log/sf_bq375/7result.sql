SELECT
  CASE
    WHEN LOWER("path") LIKE '%.py'   THEN 'Python'
    WHEN LOWER("path") LIKE '%.c'    THEN 'C'
    WHEN LOWER("path") LIKE '%.ipynb' THEN 'Jupyter Notebook'
    WHEN LOWER("path") LIKE '%.java' THEN 'Java'
    WHEN LOWER("path") LIKE '%.js'   THEN 'JavaScript'
  END                                   AS "file_type",
  COUNT(*)                              AS "file_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
WHERE (LENGTH("path") - LENGTH(REPLACE("path",'/', ''))) > 10            -- directory depth > 10
  AND (
        LOWER("path") LIKE '%.py' OR
        LOWER("path") LIKE '%.c' OR
        LOWER("path") LIKE '%.ipynb' OR
        LOWER("path") LIKE '%.java' OR
        LOWER("path") LIKE '%.js'
      )
GROUP BY "file_type"
ORDER BY "file_count" DESC NULLS LAST
LIMIT 1;