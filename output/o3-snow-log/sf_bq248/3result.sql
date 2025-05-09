WITH files_in_repos_without_python AS (
    SELECT
        f."repo_name",
        f."path",
        c."content"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"  AS f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" AS c
          ON f."id" = c."id"
    LEFT JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" AS l
          ON f."repo_name" = l."repo_name"
    WHERE l."language" IS NULL                        -- no language data
          OR LOWER(CAST(l."language" AS STRING)) NOT LIKE '%python%'   -- language list does not include python
)

SELECT
    ROUND(
        SUM( CASE
                 WHEN LOWER("path")    LIKE '%readme.md%'
                  AND LOWER("content") LIKE '%copyright (c)%'
                 THEN 1 ELSE 0
             END
        ) :: FLOAT
        /
        NULLIF( COUNT(*), 0 )
    , 4 ) AS "proportion"
FROM files_in_repos_without_python;