SELECT r."repo_name", r."watch_count" AS "Total_Combined_Count"
FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_REPOS" r
JOIN (
    SELECT DISTINCT s."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_FILES" s
    WHERE s."ref" LIKE '%master%' AND s."path" ILIKE '%.py'
) p ON r."repo_name" = p."repo_name"
JOIN GITHUB_REPOS.GITHUB_REPOS."LICENSES" l ON r."repo_name" = l."repo_name"
WHERE l."license" IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')
ORDER BY r."watch_count" DESC NULLS LAST
LIMIT 1;