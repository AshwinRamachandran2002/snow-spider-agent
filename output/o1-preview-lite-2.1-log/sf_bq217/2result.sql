SELECT COUNT(DISTINCT t."id") AS "Total_pull_requests"
FROM "GITHUB_REPOS_DATE"."YEAR"."_2023" t
JOIN "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" l
  ON t."repo":"name"::STRING = l."repo_name"
CROSS JOIN LATERAL FLATTEN(input => l."language") f
WHERE t."type" = 'PullRequestEvent'
  AND TRY_PARSE_JSON(t."payload"):"action"::STRING = 'opened'
  AND t."created_at" BETWEEN 1674000000000000 AND 1674086399999999
  AND f.value:"name"::STRING ILIKE '%JavaScript%'