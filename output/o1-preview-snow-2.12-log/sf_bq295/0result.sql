SELECT r."repo_name", r."watch_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_REPOS r
WHERE r."repo_name" IN (
    SELECT DISTINCT f."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
      ON f."id" = c."id"
    WHERE f."path" LIKE '%.py' AND c."size" < 15000 AND c."content" LIKE '%def %'
)
ORDER BY r."watch_count" DESC NULLS LAST
LIMIT 3;