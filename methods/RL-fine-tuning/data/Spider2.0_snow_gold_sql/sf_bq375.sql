SELECT LOWER(REGEXP_SUBSTR("path", '\\.[^./\\\\]+$')) AS "File_type",
       COUNT(*) AS "File_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
WHERE ARRAY_SIZE(SPLIT("path", '/')) - 1 > 10
  AND LOWER(REGEXP_SUBSTR("path", '\\.[^./\\\\]+$')) IN ('.py', '.c', '.ipynb', '.java', '.js')
GROUP BY "File_type"
ORDER BY "File_count" DESC NULLS LAST
LIMIT 1;