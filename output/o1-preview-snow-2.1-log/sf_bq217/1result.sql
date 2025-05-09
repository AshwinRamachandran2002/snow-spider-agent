SELECT COUNT(*) AS "Total_pull_requests" FROM (
  SELECT e."id"
  FROM "GITHUB_REPOS_DATE"."YEAR"."_2023" e
  JOIN "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" l
    ON LOWER(e."repo":"name"::STRING) = LOWER(l."repo_name")
    , LATERAL FLATTEN(input => l."language") f
  WHERE e."type" = 'PullRequestEvent'
    AND TO_DATE(TO_TIMESTAMP(e."created_at" / 1000000)) = '2023-01-18'
    AND PARSE_JSON(e."payload"):"action"::STRING = 'opened'
    AND f.value::STRING ILIKE '%JavaScript%'
);