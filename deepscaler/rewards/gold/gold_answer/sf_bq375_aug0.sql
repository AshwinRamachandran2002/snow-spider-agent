-- Task: From the GitHub codebase, identify which file type among Python (.py), C (.c), Jupyter Notebook (.ipynb), Java (.java), and JavaScript (.js) has the highest number of files where the directory depth—calculated as the number of '/' characters in the "path" column minus one—is greater than 10. The file type is determined by extracting the file extension from the file path. Provide the file type and the corresponding file count.

SELECT LOWER(REGEXP_SUBSTR("path", '\\.[^./\\\\]+$')) AS "File_type",
       COUNT(*) AS "File_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
WHERE ARRAY_SIZE(SPLIT("path", '/')) - 1 > 10
  AND LOWER(REGEXP_SUBSTR("path", '\\.[^./\\\\]+$')) IN ('.py', '.c', '.ipynb', '.java', '.js')
GROUP BY "File_type"
ORDER BY "File_count" DESC NULLS LAST
LIMIT 1;