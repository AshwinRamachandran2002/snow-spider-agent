WITH
-- repositories that contain the language "Shell"
REPOS_SHELL AS (
    SELECT DISTINCT l."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN (INPUT => l."language") f
    WHERE UPPER(COALESCE(f.VALUE::STRING, f.KEY::STRING)) = 'SHELL'
),
-- repositories that have Apache‑2.0 licence
REPOS_APACHE AS (
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LICENSES
    WHERE "license" = 'apache-2.0'
),
-- repositories that satisfy both conditions
ELIGIBLE_REPOS AS (
    SELECT s."repo_name"
    FROM REPOS_SHELL s
    INNER JOIN REPOS_APACHE a
            ON s."repo_name" = a."repo_name"
)
-- count commit messages that meet the length and prefix conditions
SELECT COUNT(*) AS COMMIT_MESSAGE_COUNT
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
JOIN ELIGIBLE_REPOS r
      ON c."repo_name" = r."repo_name"
WHERE LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND NOT (UPPER(c."message") LIKE 'MERGE%' 
           OR UPPER(c."message") LIKE 'UPDATE%' 
           OR UPPER(c."message") LIKE 'TEST%');