WITH "SHELL_REPOS" AS (
    SELECT DISTINCT l."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
    WHERE LOWER(f.value::string) = 'shell'
),
"APACHE_REPOS" AS (
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") = 'apache-2.0'
),
"TARGET_REPOS" AS (
    SELECT DISTINCT s."repo_name"
    FROM "SHELL_REPOS" s
    JOIN "APACHE_REPOS" a
      ON s."repo_name" = a."repo_name"
)
SELECT COUNT(*) AS "COMMIT_MESSAGE_COUNT"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
JOIN "TARGET_REPOS" tr
  ON c."repo_name" = tr."repo_name"
WHERE LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND NOT REGEXP_LIKE(LOWER(TRIM(c."message")), '^(merge|update|test)');