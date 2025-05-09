WITH python_repos AS (           -- repositories that use a language like "python"
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER(CAST("language" AS VARCHAR)) LIKE '%python%'
),
eligible_files AS (             -- files that belong to repos *not* using python
    SELECT f."repo_name",
           f."id",
           f."path"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES AS f
    LEFT JOIN python_repos AS p
           ON f."repo_name" = p."repo_name"
    WHERE p."repo_name" IS NULL
),
total_files AS (                -- denominator
    SELECT COUNT(*) AS total_cnt
    FROM eligible_files
),
matched_files AS (              -- numerator
    SELECT COUNT(*) AS match_cnt
    FROM eligible_files AS f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
         ON f."id" = c."id"
        AND f."repo_name" = c."sample_repo_name"
    WHERE LOWER(f."path") LIKE '%readme.md%'
      AND LOWER(c."content") LIKE '%copyright (c)%'
)
SELECT
       match_cnt * 1.0 / NULLIF(total_cnt,0)  AS proportion
FROM   matched_files, total_files;