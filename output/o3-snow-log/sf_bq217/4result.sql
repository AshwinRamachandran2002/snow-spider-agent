SELECT COUNT(*) AS "pull_request_creation_events"
FROM GITHUB_REPOS_DATE.YEAR."_2023" AS e
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES AS l
      ON l."repo_name" = e."repo":"name"::STRING
WHERE e."type" = 'PullRequestEvent'
  AND TRY_PARSE_JSON(e."payload"):"action"::STRING = 'opened'
  AND TO_DATE(TO_TIMESTAMP_LTZ(e."created_at" / 1000000)) = '2023-01-18'
  AND UPPER(l."language"::STRING) LIKE '%JAVASCRIPT%';