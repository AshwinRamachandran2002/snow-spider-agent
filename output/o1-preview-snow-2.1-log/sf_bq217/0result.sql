SELECT COUNT(*) AS "Total_pull_requests"
FROM "GITHUB_REPOS_DATE"."YEAR"."_2023" e
WHERE e."type" = 'PullRequestEvent'
  AND PARSE_JSON(e."payload"):"action"::STRING = 'opened'
  AND PARSE_JSON(e."payload"):"pull_request":"base":"repo":"language"::STRING = 'JavaScript'
  AND e."created_at" >= 1674000000000000 AND e."created_at" < 1674086400000000;