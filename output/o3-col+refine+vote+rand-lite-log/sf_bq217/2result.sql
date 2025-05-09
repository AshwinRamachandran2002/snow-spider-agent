SELECT
  COUNT(*) AS "pr_creation_events_with_js"
FROM GITHUB_REPOS_DATE.YEAR."_2023"            AS e
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES  AS l
  ON PARSE_JSON(e."repo"):"name"::STRING = l."repo_name"
WHERE e."type" = 'PullRequestEvent'                                 -- event kind
  AND PARSE_JSON(e."payload"):"action"::STRING = 'opened'           -- creation action
  AND TO_DATE(TO_TIMESTAMP_LTZ(e."created_at" / 1000000)) = '2023-01-18' -- events on 18-Jan-2023 (UTC)
  AND l."language" ILIKE '%JavaScript%';                            -- repos that list JavaScript