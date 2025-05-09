SELECT
    COUNT(*) AS "commit_message_count"
FROM
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS"      AS c
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LICENSES"       AS l
         ON c."repo_name" = l."repo_name"
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"      AS lang
         ON c."repo_name" = lang."repo_name"
WHERE
      LOWER(l."license") = 'apache-2.0'
  AND LOWER(lang."language"::string) LIKE '%shell%'          -- repository uses Shell
  AND c."message" IS NOT NULL
  AND LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND NOT (
        LOWER(c."message") LIKE 'merge%'   -- does not start with “merge”
     OR LOWER(c."message") LIKE 'update%'  -- does not start with “update”
     OR LOWER(c."message") LIKE 'test%'    -- does not start with “test”
  );