SELECT DISTINCT r."repo_name", r."watch_count"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
  ON c."id" = f."id"
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_REPOS" r
  ON f."repo_name" = r."repo_name"
WHERE f."path" LIKE '%.py'
  AND c."size" < 15000
  AND c."content" LIKE '%def%'
ORDER BY r."watch_count" DESC NULLS LAST
LIMIT 3;