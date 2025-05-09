SELECT 
    ROUND(
        COUNT_IF(
            "path" ILIKE '%readme.md%' 
            AND "content" ILIKE '%copyright (c)%'
        )::DECIMAL(38,6) 
        / NULLIF(COUNT(*), 0),
        4
    ) AS "proportion"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"  AS f
JOIN (
    SELECT DISTINCT "repo_name"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"
    WHERE "language" NOT ILIKE '%python%'
) AS l
  ON f."repo_name" = l."repo_name"
LEFT JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" AS c
  ON f."id" = c."id";