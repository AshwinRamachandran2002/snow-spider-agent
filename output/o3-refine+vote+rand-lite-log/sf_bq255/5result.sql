SELECT COUNT(*) AS "COMMIT_COUNT"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS      AS c
JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES           AS l
     ON c."repo_name" = l."repo_name"
JOIN GITHUB_REPOS.GITHUB_REPOS.LICENSES            AS lic
     ON c."repo_name" = lic."repo_name"
WHERE lic."license" = 'apache-2.0'
      -- repositories whose language object contains the key  'Shell'
      AND l."language":"Shell" IS NOT NULL
      -- commit‑message length constraints
      AND LENGTH(c."message") > 5
      AND LENGTH(c."message") < 10000
      -- message must not start with merge, update, or test (case‑insensitive)
      AND NOT (  LOWER(TRIM(c."message")) LIKE 'merge%'
              OR LOWER(TRIM(c."message")) LIKE 'update%'
              OR LOWER(TRIM(c."message")) LIKE 'test%' );