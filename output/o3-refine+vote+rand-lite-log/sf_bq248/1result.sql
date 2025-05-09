WITH no_python_repos AS (          -- repositories that do NOT use a language containing 'python'
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER(CAST("language" AS STRING)) NOT LIKE '%python%'
),

repo_files AS (                    -- all files that belong to the above repositories
    SELECT sf."id",
           sf."path",
           sf."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES AS sf
    JOIN no_python_repos            np
      ON sf."repo_name" = np."repo_name"
),

files_with_content AS (            -- attach file contents (may be NULL)
    SELECT rf."path",
           COALESCE(sc."content", '') AS "content"
    FROM repo_files                rf
    LEFT JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
           ON rf."id" = sc."id"
),

aggregates AS (                    -- count total and matched files
    SELECT COUNT(*) AS total_files,
           SUM(
               CASE
                   WHEN LOWER("path")     LIKE '%readme.md%'
                    AND LOWER("content")  LIKE '%copyright (c)%'
                   THEN 1 ELSE 0
               END
           ) AS matched_files
    FROM files_with_content
)

SELECT
    ROUND(matched_files::FLOAT / NULLIF(total_files, 0), 4) AS proportion
FROM aggregates;