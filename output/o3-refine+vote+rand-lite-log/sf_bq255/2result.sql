WITH shell_repos AS (   -- repositories whose language list includes “Shell”
    SELECT DISTINCT l."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
    WHERE LOWER(f.KEY::STRING)   = 'shell'
       OR LOWER(f.VALUE::STRING) = 'shell'
),
licensed_repos AS (     -- repositories licensed under Apache‑2.0
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LICENSES
    WHERE LOWER("license") = 'apache-2.0'
),
target_repos AS (       -- intersection of the two criteria above
    SELECT DISTINCT s."repo_name"
    FROM shell_repos     s
    JOIN licensed_repos  r USING ("repo_name")
)
SELECT COUNT(*) AS "COMMIT_MESSAGE_COUNT"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
JOIN target_repos tr ON c."repo_name" = tr."repo_name"
WHERE c."message" IS NOT NULL
  AND LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND NOT REGEXP_LIKE(LOWER(c."message"), '^\\s*(merge|update|test)\\b');