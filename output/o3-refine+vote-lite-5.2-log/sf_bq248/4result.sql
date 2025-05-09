WITH no_python_repos AS (
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER(CAST("language" AS STRING)) NOT LIKE '%python%'
),
readme_contents AS (
    SELECT  c."content"
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN    no_python_repos                            r  ON f."repo_name" = r."repo_name"
    JOIN    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c  ON f."id"        = c."id"
    WHERE   LOWER(f."path") LIKE '%readme.md%'
)
SELECT
    CASE 
        WHEN COUNT(*) = 0 THEN 0
        ELSE ROUND(
                 SUM(CASE WHEN LOWER("content") LIKE '%copyright (c)%' THEN 1 ELSE 0 END)::FLOAT
                 / COUNT(*),
                 4
             )
    END AS "proportion"
FROM readme_contents;