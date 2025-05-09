SELECT COUNT(DISTINCT C."commit") AS "commit_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS  AS C
JOIN GITHUB_REPOS.GITHUB_REPOS.LICENSES        AS LIC
  ON C."repo_name" = LIC."repo_name"
JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES       AS L
  ON C."repo_name" = L."repo_name"
CROSS JOIN LATERAL FLATTEN(INPUT => L."language") AS F
WHERE LOWER(LIC."license") = 'apache-2.0'
  AND LOWER(F.VALUE:"name"::STRING) = 'shell'
  AND LENGTH(C."message") BETWEEN 6 AND 9999
  AND NOT (  LOWER(C."message") LIKE 'merge%'
          OR LOWER(C."message") LIKE 'update%'
          OR LOWER(C."message") LIKE 'test%' );