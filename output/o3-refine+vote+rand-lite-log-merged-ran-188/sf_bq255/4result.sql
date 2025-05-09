SELECT COUNT(*) AS "COMMIT_COUNT"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS      AS c
JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES           AS l
      ON c."repo_name" = l."repo_name"
JOIN GITHUB_REPOS.GITHUB_REPOS.LICENSES            AS lic
      ON c."repo_name" = lic."repo_name"
WHERE LOWER(CAST(l."language" AS STRING)) LIKE '%shell%'   -- repositories that use Shell
  AND LOWER(lic."license") = 'apache-2.0'                  -- apache‑2.0 licence
  AND LENGTH(c."message") > 5                              -- message length > 5
  AND LENGTH(c."message") < 10000                          -- message length < 10 000
  AND NOT REGEXP_LIKE(c."message", '^(merge|update|test)', 'i'); -- does not start with forbidden words