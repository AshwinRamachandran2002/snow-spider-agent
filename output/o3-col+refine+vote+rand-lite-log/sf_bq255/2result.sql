WITH eligible_repos AS (
    SELECT  lang."repo_name"
    FROM    GITHUB_REPOS.GITHUB_REPOS.LANGUAGES AS lang
    JOIN    GITHUB_REPOS.GITHUB_REPOS.LICENSES  AS lic
           ON lang."repo_name" = lic."repo_name"
    WHERE   lang."language" ILIKE '%Shell%'
      AND   lic."license"  ILIKE '%apache-2.0%'
)
SELECT  COUNT(*) AS "total_messages"
FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS AS c
JOIN    eligible_repos                       AS r
       ON c."repo_name" = r."repo_name"
WHERE   LENGTH(c."message") > 5
  AND   LENGTH(c."message") < 10000
  AND   NOT (LOWER(c."message") LIKE 'merge%'
             OR LOWER(c."message") LIKE 'update%'
             OR LOWER(c."message") LIKE 'test%');