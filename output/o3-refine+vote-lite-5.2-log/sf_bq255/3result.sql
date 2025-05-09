SELECT COUNT(*) AS "commit_message_count"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS"       AS c
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"            AS l
     ON c."repo_name" = l."repo_name"
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LICENSES"             AS lic
     ON c."repo_name" = lic."repo_name"
WHERE l."language":"Shell" IS NOT NULL                   -- repository uses Shell
  AND LOWER(lic."license") = 'apache-2.0'                -- apache‑2.0 license
  AND c."message" IS NOT NULL
  AND LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND NOT (LOWER(c."message") LIKE 'merge%'              -- exclude messages starting with merge/update/test
           OR LOWER(c."message") LIKE 'update%'
           OR LOWER(c."message") LIKE 'test%');