WITH repos_without_python AS (
    SELECT DISTINCT
           "repo_name"
    FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE  LOWER("language"::string) NOT LIKE '%python%'
),

files_in_repos AS (
    SELECT  c.*
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
    JOIN    repos_without_python                      r
           ON c."sample_repo_name" = r."repo_name"
)

SELECT
       ROUND(
              SUM(
                  CASE
                      WHEN LOWER("sample_path") LIKE '%readme.md%'
                           AND LOWER("content")   LIKE '%copyright (c)%'
                      THEN 1 ELSE 0
                  END
              )::FLOAT
              / NULLIF(COUNT(*),0),
              4
       ) AS "proportion"
FROM   files_in_repos;