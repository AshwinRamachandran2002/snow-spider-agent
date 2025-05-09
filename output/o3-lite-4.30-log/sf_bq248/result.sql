WITH "readme_files" AS (
    SELECT
        f."id",
        f."repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
    WHERE LOWER(f."path") LIKE '%readme.md%'
),
"non_python_repos" AS (
    SELECT DISTINCT
        l."repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l
    WHERE LOWER(l."language"::STRING) NOT LIKE '%python%'
),
"joined_data" AS (
    SELECT
        c."content"
    FROM "readme_files" r
    JOIN "non_python_repos" n
      ON n."repo_name" = r."repo_name"
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
      ON c."id" = r."id"
)
SELECT
    ROUND(
        SUM(CASE WHEN LOWER(j."content") LIKE '%copyright (c)%' THEN 1 ELSE 0 END)::FLOAT
        / NULLIF(COUNT(*), 0),
        4
    ) AS "proportion"
FROM "joined_data" j;