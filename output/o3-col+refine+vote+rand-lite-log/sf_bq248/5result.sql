WITH python_repos AS (
    /* Repositories that use any language whose name contains "python" */
    SELECT DISTINCT l."repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
         LATERAL FLATTEN(input => l."language") f
    WHERE LOWER(f.value::STRING) LIKE '%python%'
),
all_files AS (
    /* All files belonging to NON-python repositories */
    SELECT f."id"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
    WHERE f."repo_name" NOT IN (SELECT "repo_name" FROM python_repos)
),
qualifying_files AS (
    /* Files in NON-python repos whose path contains "readme.md"
       and whose contents include "Copyright (c)" */
    SELECT f."id"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"     f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
      ON f."id" = c."id"
    WHERE f."repo_name" NOT IN (SELECT "repo_name" FROM python_repos)
      AND LOWER(f."path")    LIKE '%readme.md%'
      AND LOWER(c."content") LIKE '%copyright (c)%'
)
SELECT
    (SELECT COUNT(*) FROM qualifying_files)::FLOAT
    /
    (SELECT COUNT(*) FROM all_files) AS "proportion_copyright_readme_no_python";