SELECT
  COUNT(*) AS "pull_request_creations_with_JS"
FROM GITHUB_REPOS_DATE.YEAR."_2023"            AS e
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES  AS l
      ON l."repo_name" = e."repo":name::STRING
WHERE TO_DATE( TO_TIMESTAMP_NTZ(e."created_at" / 1000000) ) = '2023-01-18'
  AND e."type" = 'PullRequestEvent'
  AND e."payload" ILIKE '%"action":"opened"%'
  AND l."language"::STRING ILIKE '%JavaScript%';