SELECT COUNT(*) AS "COMMIT_MESSAGE_COUNT"
FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS AS c
JOIN  GITHUB_REPOS.GITHUB_REPOS.LANGUAGES      AS l
      ON c."repo_name" = l."repo_name"
JOIN  GITHUB_REPOS.GITHUB_REPOS.LICENSES       AS lic
      ON c."repo_name" = lic."repo_name"
WHERE lic."license" = 'apache-2.0'
  AND l."language"::STRING ILIKE '%Shell%'          -- repository uses Shell
  AND LENGTH(c."message") > 5
  AND LENGTH(c."message") < 10000
  AND LOWER(LTRIM(c."message")) NOT LIKE 'merge%'   -- message does not start with forbidden words
  AND LOWER(LTRIM(c."message")) NOT LIKE 'update%'
  AND LOWER(LTRIM(c."message")) NOT LIKE 'test%';