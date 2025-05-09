SELECT COUNT(*) AS "COMMIT_COUNT"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS          AS c
JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES               AS l
     ON c."repo_name" = l."repo_name"
JOIN GITHUB_REPOS.GITHUB_REPOS.LICENSES                AS lic
     ON c."repo_name" = lic."repo_name"
WHERE lic."license" ILIKE 'apache-2.0'                       -- licence filter
  AND l."language"::string ILIKE '%Shell%'                   -- repository uses Shell
  AND c."message" IS NOT NULL                                -- non‑null messages
  AND LENGTH(c."message") > 5                                -- message length > 5
  AND LENGTH(c."message") < 10000                            -- message length < 10 000
  AND NOT (                                                  -- exclude messages starting with merge/update/test
          LOWER(REGEXP_REPLACE(c."message", '^\s+', '')) LIKE 'merge%'  OR
          LOWER(REGEXP_REPLACE(c."message", '^\s+', '')) LIKE 'update%' OR
          LOWER(REGEXP_REPLACE(c."message", '^\s+', '')) LIKE 'test%'
         );