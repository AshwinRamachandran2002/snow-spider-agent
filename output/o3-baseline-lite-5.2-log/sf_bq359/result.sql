SELECT
    c."repo_name",
    c."commit_count"
FROM (
    SELECT 
        "repo_name",
        COUNT(*) AS "commit_count"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    GROUP BY "repo_name"
) c
JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l
      ON c."repo_name" = l."repo_name"
WHERE LOWER(l."language"::string) LIKE '%"javascript"%'
ORDER BY 
    c."commit_count" DESC NULLS LAST,
    c."repo_name"
LIMIT 2;