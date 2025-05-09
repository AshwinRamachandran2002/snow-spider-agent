WITH shell_repos AS (
    SELECT DISTINCT l."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
    WHERE LOWER(COALESCE(f.key::string, f.value::string)) = 'shell'
),
apache_shell_repos AS (
    SELECT DISTINCT lic."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LICENSES lic
    JOIN shell_repos sr
      ON sr."repo_name" = lic."repo_name"
    WHERE LOWER(lic."license") = 'apache-2.0'
)
SELECT COUNT(*) AS "commit_message_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
JOIN apache_shell_repos r
  ON r."repo_name" = c."repo_name"
WHERE LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND NOT REGEXP_LIKE(LTRIM(LOWER(c."message")), '^(merge|update|test)');