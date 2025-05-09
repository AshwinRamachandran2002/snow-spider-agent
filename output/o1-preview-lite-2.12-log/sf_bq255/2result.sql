SELECT COUNT(*) AS "Commit_Message_Count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
INNER JOIN (
    SELECT DISTINCT t."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES t
    WHERE t."language" IS NOT NULL
      AND t."language"::STRING ILIKE '%Shell%'
) AS shell_repos ON c."repo_name" = shell_repos."repo_name"
INNER JOIN GITHUB_REPOS.GITHUB_REPOS.LICENSES l
    ON c."repo_name" = l."repo_name"
WHERE l."license" = 'apache-2.0'
  AND LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND LOWER(c."message") NOT LIKE 'merge%'
  AND LOWER(c."message") NOT LIKE 'update%'
  AND LOWER(c."message") NOT LIKE 'test%';