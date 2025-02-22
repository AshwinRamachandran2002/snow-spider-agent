-- Task: Find the count of files for each of the file types .py, .c, .ipynb, .java, and .js in the GitHub codebase.
SELECT LOWER(REGEXP_SUBSTR("path", '\\.[^./\\\\]+$')) AS "File_type",
       COUNT(*) AS "File_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
WHERE LOWER(REGEXP_SUBSTR("path", '\\.[^./\\\\]+$')) IN ('.py', '.c', '.ipynb', '.java', '.js')
GROUP BY "File_type"
ORDER BY "File_count" DESC NULLS LAST;