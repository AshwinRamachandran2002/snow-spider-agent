WITH repos_with_shell AS (
    SELECT DISTINCT
           l."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
    WHERE LOWER(f.value:"name"::STRING) = 'shell'          -- repositories that use Shell
), repos_with_apache AS (
    SELECT DISTINCT
           "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") = 'apache-2.0'                  -- repositories under Apache-2.0
), qualified_repos AS (
    SELECT s."repo_name"
    FROM repos_with_shell  s
    JOIN repos_with_apache a
      ON s."repo_name" = a."repo_name"                     -- repos meeting both conditions
)
SELECT COUNT(*) AS "qualified_commit_messages"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
JOIN qualified_repos r
  ON c."repo_name" = r."repo_name"
WHERE LENGTH(c."message") > 5                              -- message length > 5
  AND LENGTH(c."message") < 10000                          -- message length < 10 000
  AND NOT (LOWER(c."message") LIKE 'merge%'                -- exclude messages starting with merge
           OR LOWER(c."message") LIKE 'update%'            -- exclude messages starting with update
           OR LOWER(c."message") LIKE 'test%');            -- exclude messages starting with test