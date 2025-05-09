WITH non_python_repos AS (
    SELECT  "repo_name"
    FROM    GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE   NOT LOWER(TO_VARCHAR("language")) LIKE '%python%'
),

files_in_repos AS (
    SELECT  f."repo_name",
            f."id",
            f."path"
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES   f
    JOIN    non_python_repos                          np
           ON f."repo_name" = np."repo_name"
),

files_with_content AS (
    SELECT  fir."repo_name",
            fir."path",
            c."content"
    FROM    files_in_repos                 fir
    JOIN    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
           ON c."id" = fir."id"
)

SELECT  COUNT_IF(
            LOWER("path")    LIKE '%readme.md%' 
        AND LOWER("content") LIKE '%copyright (c)%'
        )        :: FLOAT
        /
        COUNT(*) :: FLOAT       AS proportion
FROM    files_with_content;