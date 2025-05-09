WITH python_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER("language"::string) LIKE '%python%'
),
eligible_files AS (
    SELECT *
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_repo_name" NOT IN (SELECT "repo_name" FROM python_repos)
      AND "binary" = FALSE
)
SELECT
    ROUND(
        COUNT_IF(
            LOWER("sample_path") LIKE '%readme.md%' 
            AND LOWER("content") LIKE '%copyright (c)%'
        )::FLOAT
        / NULLIF(COUNT(*), 0),
        4
    ) AS "proportion"
FROM eligible_files;