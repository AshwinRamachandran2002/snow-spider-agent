SELECT COUNT(*) AS "commit_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS C
JOIN (
        SELECT LIC."repo_name"
        FROM GITHUB_REPOS.GITHUB_REPOS.LICENSES  LIC
        JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES LANG
              ON LIC."repo_name" = LANG."repo_name"
        WHERE LOWER(LIC."license") = 'apache-2.0'
          AND LOWER(CAST(LANG."language" AS STRING)) LIKE '%shell%'
     ) R
       ON C."repo_name" = R."repo_name"
WHERE LENGTH(C."message") > 5
  AND LENGTH(C."message") < 10000
  AND NOT REGEXP_LIKE(C."message", '^(merge|update|test)', 'i');