SELECT 
    "repo_name",
    COUNT(*) AS "commit_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
WHERE "repo_name" IN (
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER(TO_VARCHAR("language")) LIKE '%javascript%'
)
GROUP BY "repo_name"
ORDER BY "commit_count" DESC NULLS LAST, "repo_name" ASC
LIMIT 2;