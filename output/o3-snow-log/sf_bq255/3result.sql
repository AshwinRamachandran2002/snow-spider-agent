WITH
  shell_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER("language"::string) = 'shell'
  ),
  apache_repos AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") = 'apache-2.0'
  ),
  target_repos AS (
    SELECT s."repo_name"
    FROM shell_repos s
    INNER JOIN apache_repos a
      ON s."repo_name" = a."repo_name"
  )
SELECT COUNT(*) AS "commit_message_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
WHERE "repo_name" IN (SELECT "repo_name" FROM target_repos)
  AND "message" IS NOT NULL
  AND LENGTH("message") > 5
  AND LENGTH("message") < 10000
  AND NOT (
        LOWER("message") LIKE 'merge%'
     OR LOWER("message") LIKE 'update%'
     OR LOWER("message") LIKE 'test%'
  );