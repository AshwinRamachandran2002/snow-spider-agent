WITH python_repos AS (   -- repos that use any language containing "python"
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER(CAST("language" AS STRING)) LIKE '%python%'
),
eligible_files AS (      -- files belonging to repos WITHOUT such languages
    SELECT "sample_repo_name",
           "sample_path",
           "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_repo_name" NOT IN (SELECT "repo_name" FROM python_repos)
)
SELECT
    ROUND(
        SUM(
            CASE
                WHEN LOWER("sample_path") LIKE '%readme.md%' 
                 AND LOWER("content") LIKE '%copyright (c)%'
                THEN 1 ELSE 0
            END
        )::FLOAT
        /
        NULLIF(COUNT(*), 0),
        4
    ) AS "proportion"
FROM eligible_files;