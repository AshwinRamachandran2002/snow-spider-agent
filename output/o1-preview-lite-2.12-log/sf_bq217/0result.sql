SELECT COUNT(*) AS "Number_of_Pull_Requests"
FROM "GITHUB_REPOS_DATE"."DAY"."_20230118" e
JOIN (
    SELECT DISTINCT "repo_name"
    FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES", LATERAL FLATTEN(input => "language") l
    WHERE l.value::STRING ILIKE '%JavaScript%'
) j
  ON e."repo"::VARIANT:"name"::STRING = j."repo_name"
WHERE e."type" = 'PullRequestEvent';