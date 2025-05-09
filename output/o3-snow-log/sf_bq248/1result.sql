WITH "filtered_files" AS (
    SELECT
        sc."content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
    LEFT JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l
        ON sc."sample_repo_name" = l."repo_name"
    WHERE (l."repo_name" IS NULL 
           OR LOWER(l."language"::STRING) NOT LIKE '%python%')   -- repos without any "python" language
      AND LOWER(sc."sample_path") LIKE '%readme.md%'            -- files whose paths include "readme.md"
)
SELECT
    ROUND(
        SUM(CASE WHEN LOWER("content") LIKE '%copyright (c)%' THEN 1 ELSE 0 END)::FLOAT
        / NULLIF(COUNT(*), 0),                                  -- proportion of matching files
        4
    ) AS "proportion"
FROM "filtered_files";