SELECT r."repo_name", r."watch_count"
FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS r
JOIN (
    SELECT DISTINCT t."repo":"name"::STRING AS "repo_name"
    FROM GITHUB_REPOS_DATE.YEAR."_2017" t
) t2017 ON r."repo_name" = t2017."repo_name"
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_CONTENTS c
  ON r."repo_name" = c."sample_repo_name"
WHERE r."watch_count" > 30
  AND c."content" LIKE '%Copyright (c)%'
GROUP BY r."repo_name", r."watch_count"
ORDER BY r."watch_count" DESC NULLS LAST
LIMIT 2;