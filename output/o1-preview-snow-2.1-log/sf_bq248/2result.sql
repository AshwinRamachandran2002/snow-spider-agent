WITH python_repos AS (
  SELECT DISTINCT l."repo_name"
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
       LATERAL FLATTEN(INPUT => l."language") f
  WHERE f.value:"name"::STRING ILIKE '%python%'
)
SELECT
  ROUND(
    COUNT(CASE WHEN c."content" ILIKE '%Copyright (c)%' THEN 1 END)::FLOAT /
    NULLIF(COUNT(*), 0), 4
  ) AS "proportion"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c ON f."id" = c."id"
LEFT JOIN python_repos pr ON f."repo_name" = pr."repo_name"
WHERE f."path" ILIKE '%readme.md%'
  AND pr."repo_name" IS NULL;