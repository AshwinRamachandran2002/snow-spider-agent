WITH pythonless_repos AS (
    SELECT l."repo_name"
    FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l
    WHERE  LOWER(TO_VARCHAR(l."language")) NOT LIKE '%python%'          -- exclude any language containing “python”
), 
readme_files AS (                                  -- README.md files in those repos
    SELECT f."id"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
    JOIN   pythonless_repos r
           ON r."repo_name" = f."repo_name"
    WHERE  LOWER(f."path") LIKE '%readme.md%'
),
readme_with_content AS (                           -- keep only files whose content is available
    SELECT c."content"
    FROM   readme_files           rf
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
           ON c."id" = rf."id"
)
SELECT
    COUNT_IF(LOWER("content") LIKE '%copyright (c)%')::FLOAT
    / NULLIF(COUNT(*), 0)         AS "proportion"
FROM readme_with_content;