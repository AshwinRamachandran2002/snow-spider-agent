SELECT DISTINCT t."repo"::VARIANT:"name"::STRING AS "repo_name", s."watch_count"
FROM "GITHUB_REPOS_DATE"."YEAR"."_2017" t
JOIN "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_REPOS" s
  ON t."repo"::VARIANT:"name"::STRING = s."repo_name"
JOIN "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
  ON s."repo_name" = c."sample_repo_name"
WHERE s."watch_count" > 30 AND c."content" ILIKE '%Copyright (c)%'
ORDER BY s."watch_count" DESC NULLS LAST
LIMIT 2;