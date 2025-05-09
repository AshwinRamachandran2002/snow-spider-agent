WITH repos_with_shell AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER(CAST("language" AS STRING)) LIKE '%shell%'
), repos_with_apache AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") = 'apache-2.0'
), target_repos AS (
    SELECT s."repo_name"
    FROM repos_with_shell  s
    INNER JOIN repos_with_apache a
            ON s."repo_name" = a."repo_name"
)
SELECT COUNT(*) AS "commit_message_count"
FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
JOIN   target_repos r
       ON c."repo_name" = r."repo_name"
WHERE  c."message" IS NOT NULL
  AND  LENGTH(c."message") > 5
  AND  LENGTH(c."message") < 10000
  AND  NOT REGEXP_LIKE(LOWER(c."message"), '^\s*(merge|update|test)');