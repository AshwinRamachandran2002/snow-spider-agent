SELECT COUNT(*) AS "pr_creation_events_js"
FROM "GITHUB_REPOS_DATE"."YEAR"."_2023" AS e
JOIN "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LANGUAGES" AS l
  ON l."repo_name" = (PARSE_JSON(e."repo"):name)::STRING
WHERE e."type" = 'PullRequestEvent'
  AND (PARSE_JSON(e."payload"):action)::STRING = 'opened'
  -- 2023-01-18 00:00:00‒23:59:59 UTC, timestamps in microseconds
  AND e."created_at" BETWEEN 1674000000 * 1000000 AND 1674086399 * 1000000
  -- repository lists JavaScript among its languages
  AND l."language" ILIKE '%JavaScript%';