SELECT COUNT(*) AS "commit_message_count"
FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS  C
JOIN   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES       L   ON C."repo_name" = L."repo_name"
JOIN   GITHUB_REPOS.GITHUB_REPOS.LICENSES        LIC ON C."repo_name" = LIC."repo_name"
WHERE  L."language"::STRING ILIKE '%shell%'
  AND  LIC."license"         ILIKE '%apache-2.0%'
  AND  LENGTH(C."message")  > 5
  AND  LENGTH(C."message")  < 10000
  AND  LOWER(C."message") NOT LIKE 'merge%'
  AND  LOWER(C."message") NOT LIKE 'update%'
  AND  LOWER(C."message") NOT LIKE 'test%';