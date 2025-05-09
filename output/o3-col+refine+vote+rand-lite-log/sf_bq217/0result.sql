SELECT 
    COUNT(*) AS "pull_request_creations_js_repos_2023_01_18"
FROM "GITHUB_REPOS_DATE"."YEAR"."_2023"         AS e
JOIN "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" AS l
      ON l."repo_name" = e."repo":name::STRING
WHERE e."type" = 'PullRequestEvent'
  AND e."payload" ILIKE '%"action":"opened"%'
  AND e."created_at" >= DATE_PART(EPOCH_MICROSECOND, '2023-01-18 00:00:00'::TIMESTAMP_NTZ)
  AND e."created_at" <  DATE_PART(EPOCH_MICROSECOND, '2023-01-19 00:00:00'::TIMESTAMP_NTZ)
  AND l."language"::STRING ILIKE '%JavaScript%';