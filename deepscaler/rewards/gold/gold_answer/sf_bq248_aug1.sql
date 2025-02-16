-- Task: List the ids, repository names, and paths of all files whose paths include 'readme.md' in repositories where none of the programming languages used have names including the substring 'python' (case-insensitive).
WITH non_python_repos AS (
    SELECT 
        "repo_name"
    FROM 
        GITHUB_REPOS.GITHUB_REPOS.LANGUAGES,
        LATERAL FLATTEN(input => "language") AS language_struct
    GROUP BY
        "repo_name"
    HAVING
        SUM(CASE WHEN LOWER(language_struct.value:"name"::STRING) LIKE '%python%' THEN 1 ELSE 0 END) = 0
)
SELECT
    "id",
    "repo_name",
    "path"
FROM
    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
WHERE
    LOWER("path") LIKE '%readme.md'
    AND "repo_name" IN (SELECT "repo_name" FROM non_python_repos);