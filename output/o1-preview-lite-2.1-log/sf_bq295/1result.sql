SELECT c."sample_repo_name" AS "repo_name", r."watch_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_REPOS r
  ON c."sample_repo_name" = r."repo_name"
WHERE c."sample_path" LIKE '%.py'
  AND c."size" < 15000
  AND c."content" ILIKE '%def%'
GROUP BY c."sample_repo_name", r."watch_count"
ORDER BY r."watch_count" DESC NULLS LAST
LIMIT 3;