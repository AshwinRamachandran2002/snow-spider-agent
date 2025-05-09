WITH lang_shell AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES,
         LATERAL FLATTEN(INPUT => "language") f
    WHERE LOWER(f.value:"name"::STRING) = 'shell'
),
licensed AS (
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") = 'apache-2.0'
),
qualified_repos AS (
    SELECT ls."repo_name"
    FROM lang_shell ls
    JOIN licensed l ON l."repo_name" = ls."repo_name"
)
SELECT COUNT(*) AS "commit_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
JOIN qualified_repos r
  ON r."repo_name" = c."repo_name"
WHERE LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND NOT (
        LOWER(c."message") LIKE 'merge%'
     OR LOWER(c."message") LIKE 'update%'
     OR LOWER(c."message") LIKE 'test%'
  );