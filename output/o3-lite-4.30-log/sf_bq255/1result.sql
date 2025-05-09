SELECT COUNT(*) AS "commit_message_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS AS s
JOIN (
        SELECT DISTINCT l."repo_name"
        FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES  AS l
        JOIN GITHUB_REPOS.GITHUB_REPOS.LICENSES   AS lic
              ON l."repo_name" = lic."repo_name"
        WHERE l."language" ILIKE '%Shell%'
          AND lic."license" = 'apache-2.0'
     ) AS r
       ON s."repo_name" = r."repo_name"
WHERE LEN(s."message") > 5
  AND LEN(s."message") < 10000
  AND NOT (LOWER(LTRIM(s."message")) LIKE 'merge%'
           OR LOWER(LTRIM(s."message")) LIKE 'update%'
           OR LOWER(LTRIM(s."message")) LIKE 'test%');