SELECT COUNT(*) AS "pull_requests_opened_js_repos_2023_01_18"
FROM   GITHUB_REPOS_DATE.YEAR._2023           e
JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES l
       ON  e."repo":"name"::STRING = l."repo_name"
WHERE  e."type" = 'PullRequestEvent'
  AND  TRY_PARSE_JSON(e."payload"):"action"::STRING = 'opened'
  -- 2023-01-18 00:00 ≤ created_at < 2023-01-19 00:00 (timestamps are in µs)
  AND  e."created_at" >= 1674000000000000
  AND  e."created_at" <  1674172800000000
  -- repository language list contains “JavaScript”
  AND  l."language"::STRING ILIKE '%javascript%';