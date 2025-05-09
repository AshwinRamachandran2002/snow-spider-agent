SELECT COUNT(*) AS "COMMIT_COUNT"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS            AS c
JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES                 AS l
     ON c."repo_name" = l."repo_name"
JOIN GITHUB_REPOS.GITHUB_REPOS.LICENSES                  AS lic
     ON c."repo_name" = lic."repo_name"
WHERE LOWER(lic."license") = 'apache-2.0'                   -- repositories with Apache‑2.0 license
  AND LOWER(l."language"::STRING) LIKE '%shell%'            -- repositories that use Shell
  AND LENGTH(c."message") > 5                               -- message longer than 5 characters
  AND LENGTH(c."message") < 10000                           -- message shorter than 10,000 characters
  AND NOT (                                                  -- message does NOT start with merge/update/test
        LOWER(c."message") LIKE 'merge%'  OR
        LOWER(c."message") LIKE 'update%' OR
        LOWER(c."message") LIKE 'test%'
      );