WITH python_repos AS (               -- repos that declare any language containing "python"
    SELECT DISTINCT l."repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"  l,
         LATERAL FLATTEN(input => l."language")     lang
    WHERE LOWER(lang.value::STRING) LIKE '%python%'
),
non_python_repos AS (                -- repos that do NOT mention such a language
    SELECT DISTINCT l."repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"  l
    WHERE l."repo_name" NOT IN (SELECT "repo_name" FROM python_repos)
),
files_non_py AS (                    -- all files that belong to the non-python repos
    SELECT f.*
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
    JOIN non_python_repos np
      ON f."repo_name" = np."repo_name"
),
stats AS (                           -- compute numerator and denominator
    SELECT
        COUNT_IF(
            LOWER(f."path")     LIKE '%readme.md%'              -- path contains "readme.md"
            AND LOWER(c."content") LIKE '%copyright (c)%'       -- content has "Copyright (c)"
        )                                        AS numerator,
        COUNT(*)                                 AS denominator
    FROM   files_non_py             f
    JOIN   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
      ON   f."id" = c."id"
)
SELECT
    numerator,
    denominator,
    CASE
        WHEN denominator = 0 THEN NULL
        ELSE numerator::FLOAT / denominator
    END                                           AS proportion
FROM stats;