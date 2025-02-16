-- Task: List the repository names and paths of all README.md files.

SELECT 
    "repo_name",
    "path"
FROM 
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"
WHERE 
    LOWER("path") LIKE '%readme.md';