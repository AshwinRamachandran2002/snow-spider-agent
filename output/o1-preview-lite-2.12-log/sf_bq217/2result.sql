SELECT COUNT(*) AS "Number_of_Pull_Requests"
FROM GITHUB_REPOS_DATE.DAY."_20230118" e
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES l
  ON e."repo"::VARIANT:"name" = l."repo_name"
WHERE e."type" = 'PullRequestEvent'
  AND l."language"::VARIANT::STRING ILIKE '%JavaScript%';