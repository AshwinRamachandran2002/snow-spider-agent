WITH non_python_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER("language") NOT LIKE '%python%'
)
SELECT
    ROUND(
        SUM(
            CASE
                WHEN LOWER(f."path")      LIKE '%readme.md%'
                 AND LOWER(c."content")   LIKE '%copyright (c)%'
                THEN 1 ELSE 0
            END
        )::FLOAT
        / COUNT(*),
        4
    ) AS "proportion"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES   AS f
LEFT JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
       ON f."id" = c."id"
WHERE f."repo_name" IN (SELECT "repo_name" FROM non_python_repos);