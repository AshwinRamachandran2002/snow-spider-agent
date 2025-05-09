SELECT COUNT(*) AS "pr_creation_events"
FROM GITHUB_REPOS_DATE.YEAR."_2023" AS e
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS."LANGUAGES" AS l
  ON e."repo":"name"::STRING = l."repo_name"
WHERE e."type" = 'PullRequestEvent'
  AND e."created_at" >= 1674009600000000        -- 2023-01-18 00:00:00 UTC
  AND e."created_at" <  1674096000000000        -- 2023-01-19 00:00:00 UTC
  AND e."payload" ILIKE '%"action":"opened"%'   -- PR creation events
  AND l."language"::STRING ILIKE '%JavaScript%';