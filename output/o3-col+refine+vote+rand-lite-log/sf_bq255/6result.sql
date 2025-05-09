SELECT 
  COUNT(*) AS "qualified_commit_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS   AS c
JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES        AS l
  ON c."repo_name" = l."repo_name"
JOIN GITHUB_REPOS.GITHUB_REPOS.LICENSES         AS s
  ON c."repo_name" = s."repo_name"
WHERE l."language" ILIKE '%shell%'
  AND s."license" = 'apache-2.0'
  AND LEN(c."message") BETWEEN 6 AND 9999
  AND NOT (
        LOWER(c."message") LIKE 'merge%' 
     OR LOWER(c."message") LIKE 'update%' 
     OR LOWER(c."message") LIKE 'test%'
  );