SELECT COUNT(*) AS "commit_message_count"
FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS  c
JOIN  (
        /* repositories that use Shell AND have apache-2.0 licence */
        SELECT DISTINCT l."repo_name"
        FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES  l
        JOIN   GITHUB_REPOS.GITHUB_REPOS.LICENSES   s
               ON l."repo_name" = s."repo_name"
        WHERE  LOWER(CAST(l."language" AS STRING)) LIKE '%shell%'
          AND  LOWER(s."license") = 'apache-2.0'
      ) r
      ON c."repo_name" = r."repo_name"
WHERE  c."message" IS NOT NULL
  AND  LENGTH(c."message") > 5
  AND  LENGTH(c."message") < 10000
  AND  NOT REGEXP_LIKE(c."message",
                       '^[[:space:]]*(merge|update|test)',
                       'i');