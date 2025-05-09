SELECT COUNT(*) AS "commit_message_count"
FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS      AS c
JOIN  (
        /* repositories that both use Shell and are apache-2.0 licensed */
        SELECT DISTINCT l."repo_name"
        FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES  AS l
        JOIN   GITHUB_REPOS.GITHUB_REPOS.LICENSES   AS lic
               ON l."repo_name" = lic."repo_name"
        WHERE  LOWER(CAST(l."language" AS STRING)) LIKE '%shell%'
          AND  LOWER(lic."license") = 'apache-2.0'
       )                                           AS r
       ON c."repo_name" = r."repo_name"
WHERE  c."message" IS NOT NULL
  AND  LENGTH(c."message")  > 5
  AND  LENGTH(c."message") < 10000
  AND  NOT REGEXP_LIKE(LOWER(c."message"), '^(merge|update|test)\b');